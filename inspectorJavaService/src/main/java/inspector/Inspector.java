/* MIT
 *
 * Copyright (C) 2019 Saverio Giallorenzo <saverio.giallorenzo@gmail.com>
 * Copyright (c) 2022 Vicki Mixen <vicki@mixen.dk>
 * Copyright (C) 2022 Fabrizio Montesi <famontesi@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.from console import Console
 */

package inspector;

import jolie.cli.CommandLineException;
import jolie.cli.CommandLineParser;
import jolie.Interpreter;
import jolie.lang.CodeCheckException;
import jolie.lang.CodeCheckMessage;
import jolie.lang.parse.ParserException;
import jolie.lang.parse.SemanticVerifier;
import jolie.lang.parse.ast.*;
import jolie.lang.parse.ast.types.TypeChoiceDefinition;
import jolie.lang.parse.ast.types.TypeDefinition;
import jolie.lang.parse.ast.types.TypeDefinitionLink;
import jolie.lang.parse.ast.types.TypeInlineDefinition;
import jolie.lang.parse.context.ParsingContext;
import jolie.lang.parse.module.ModuleException;
import jolie.lang.parse.module.ModuleSource;
import jolie.lang.parse.module.ImportedSymbolInfo;
import jolie.lang.parse.module.LocalSymbolInfo;
import jolie.lang.parse.util.Interfaces;
import jolie.lang.parse.util.ParsingUtils;
import jolie.lang.parse.util.ProgramInspector;
import jolie.runtime.FaultException;
import jolie.runtime.JavaService;
import jolie.runtime.Value;
import jolie.runtime.ValueVector;
import jolie.runtime.embedding.RequestResponse;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import java.util.stream.Stream;

//@AndJarDeps( "jolie-inspector-0.1.0.jar" )
public class Inspector extends JavaService {
	private static final class FileInspectionResponse {
		private static final String INPUT_PORT = "inputPorts";
		private static final String OUTPUT_PORT = "outputPorts";
		private static final String REFERRED_TYPES = "referredTypes";
	}

	private static final class PortInspectionResponse {
		private static final String INPUT_PORT = "inputPorts";
		private static final String OUTPUT_PORT = "outputPorts";
		private static final String REFERRED_TYPES = "referredTypes";
	}

	private static final class PortInfoType {
		private static final String NAME = "name";
		private static final String LOCATION = "location";
		private static final String PROTOCOL = "protocol";
		private static final String INTERFACE = "interfaces";
		private static final String DOCUMENTATION = "documentation";
	}

	private static final class InterfaceInfoType {
		private static final String NAME = "name";
		private static final String OPERATION = "operations";
		private static final String DOCUMENTATION = "documentation";
	}

	private static final class OperationInfoType {
		private static final String NAME = "name";
		private static final String REQUEST_TYPE = "requestType";
		private static final String RESPONSE_TYPE = "responseType";
		private static final String FAULT = "faults";
		private static final String DOCUMENTATION = "documentation";
	}

	private static final class TypeDefinitionInfoType {
		private static final String NAME = "name";
		private static final String TYPE = "type";
	}

	private static final class TypeInfoType {
		private static final String DOCUMENTATION = "documentation";
		private static final String FIELDS = "fields";
		private static final String UNTYPED_FIELDS = "untypedFields";
		private static final String NATIVE_TYPE = "nativeType";
		private static final String LINKED_TYPE_NAME = "linkedTypeName";
		private static final String LEFT = "left";
		private static final String RIGHT = "right";
	}

	private static final class FaultInfoType {
		private static final String NAME = "name";
		private static final String TYPE = "type";
	}

	private static final class FieldType {
		private static final String NAME = "name";
		private static final String RANGE = "range";
		private static final String TYPE = "type";
		private static final String MIN = "min";
		private static final String MAX = "max";
	}

	/**
	 * Used in languageserver/internal/inspection-utils.ol callInspection
	 * Outputs information about the file or errors in case it does not compile
	 * @param request InspectionRequest: contains list of includePaths, source as a string, fileName as a string
	 * @return PortInspectionResponse, 
	 * @throws FaultException which can either be a CommandLine, IO or CodeCheck exception
	 */
	@RequestResponse
	public Value inspectFile( Value request ) throws FaultException {
		System.out.println("Inside inspectFile");
		try {
			final ProgramInspector inspector;
			String[] includePaths =
				request.getChildren( "includePaths" ).stream().map( Value::strValue ).toArray( String[]::new );
			String source = request.getFirstChild( "source" ).strValue();
			String fileName = request.getFirstChild( "filename" ).strValue();
			inspector = getInspector( fileName, Optional.of(source), includePaths, interpreter() );
			System.out.println("No error was thrown while running getInspector");
			return buildPortInspectionResponse( inspector );
		} catch( CodeCheckException ex ) {
			// Create a value containing the information needed from the CodeCheckException to create the correct diagnostic
			// in the language server
			Value codeCheckExceptionType = Value.create();
			for(CodeCheckMessage msg : ex.messages()){
				Value codeCheckMessage = Value.create();
				Value context = Value.create();
				if (!msg.context().isEmpty()){
					context.getNewChild("startLine").setValue(msg.context().get().startLine());
					context.getNewChild("endLine").setValue(msg.context().get().endLine());
					context.getNewChild("startColumn").setValue(msg.context().get().startColumn());
					context.getNewChild("endColumn").setValue(msg.context().get().endColumn());
					codeCheckMessage.getNewChild("context").deepCopy(context);
				}
				if (!msg.description().isEmpty()){
					codeCheckMessage.getNewChild("description").setValue(msg.description().get());
				}
				if (!msg.help().isEmpty()){
					codeCheckMessage.getNewChild("help").setValue(msg.help().get());
				}
				codeCheckExceptionType.getChildren("exceptions").add(codeCheckMessage);
			}
			throw new FaultException("CodeCheckException", codeCheckExceptionType);
		} catch( Exception ex) {
			throw new FaultException( ex );
		}
	}

	/**
	 * Used in languageserver/internal/text-document.ol Definition call
	 * @param request ModuleInspectionRequest: contains list of includePaths, character (int describing number character on line), line (int describing line),
	 * fileName (string), source (source code as string)
	 * @return ModuleInspectionResponse: a module, containing a context and a symbol name
	 */
	@RequestResponse
	public Value inspectModule( Value request ) {
		Value result = Value.create();
		String[] includePaths =	request.getChildren( "includePaths" ).stream().map( Value::strValue ).toArray( String[]::new );
		int column = request.getFirstChild("position").getFirstChild("character").intValue();
		int line = request.getFirstChild("position").getFirstChild("line").intValue();
		String fileName = request.getFirstChild( "filename" ).strValue();
		String source = request.getFirstChild( "source" ).strValue();
		String wordWeAreLookingFor = "";
		try {
			// find the word we are looking for by checking the position in the source and calculating the word
			wordWeAreLookingFor = findWordWeAreLookingFor(fileName, column, line, Optional.of(source));

			//get the parseResult which contains the map of symbolTables
			final SemanticVerifier parseResult = getModuleInspector( fileName, Optional.of( source ), includePaths, interpreter() );
			
			// get the symbolTables for the file the request comes from
			File file = new File(fileName);
			for (ImportedSymbolInfo importedSymbol : parseResult.symbolTables().get(file.toURI()).importedSymbolInfos()) { //check if the symbol is imported first
				if(wordWeAreLookingFor.equals(importedSymbol.name())){
					Value module = buildSymbolResponse(importedSymbol.node().context().source().toString(), importedSymbol.node().context(), importedSymbol.originalSymbolName());
					result.getNewChild("module").deepCopy(module);
				}				
			}
			for (LocalSymbolInfo localSymbol : parseResult.symbolTables().get(file.toURI()).localSymbols()) { // if the symbol is not imported, check the local symbols
				if(wordWeAreLookingFor.equals(localSymbol.name())){
					Value module = buildSymbolResponse(localSymbol.context().source().toString(), localSymbol.context(), localSymbol.name());
					result.getNewChild("module").deepCopy(module);
				}
			}
			// we do not have to wory about the module in the result being overwritten in the two loops,
			// as no symbolname can be used twice, and is therefor only in the symboltables once
			return result;
		} catch( Exception ex) { //Exceptions from the compiler do not matter, as they are found by the fileinspector whenever the file is changed
			System.out.println("Could not search for symbol '"+wordWeAreLookingFor+"'. An exception happened while inspecting module.\n"+ex.getMessage());
		}
		return result;
	}

	/**
	 * Is used in languageserver/internal/workspace.ol symbol call
	 * @param request WorkspaceModulesInspectionRequest: list of includePaths, rootUri as a string, symbol name as a string
	 * @return MoreSymbolsPerModule: list of modules, each containing a list symbols with a name and a context
	 * TODO: When the symboltables contain all occurences of the same symbol in the same module, we need to return those as well
	 */
	@RequestResponse
	public Value inspectWorkspaceModules( Value request ) {
		// Create return Value
		Value result = Value.create();
		// Get request information
		String[] includePaths =	request.getChildren( "includePaths" ).stream().map( Value::strValue ).toArray( String[]::new );
		String rootUri = request.getFirstChild( "rootUri" ).strValue();
		String wordWeAreLookingFor = request.getFirstChild("symbol").strValue();
		
		try {
			// Go through all modules in workspace and look for the symbol
			File rootPath = new File(rootUri);
			Stream<Path> allFiles = Files.walk(rootPath.toPath());
			File[] olFiles = allFiles.filter(Files::isRegularFile).filter(path -> path.toString().endsWith(".ol")).map(Path::toFile).toArray( File[]::new );
			allFiles.close();
			ValueVector modules = result.getChildren("module");
			for (File olfile : olFiles) {
				String source = Files.readString(olfile.toPath());
				try{
					//get the parseResult which contains the map of symbolTables
					final SemanticVerifier parseResult = getModuleInspector( olfile.toString(), Optional.of( source ), includePaths, interpreter() );
					
					Value module = Value.create(olfile.toString());
					ValueVector symbols = module.getChildren("symbol");
					//check the imported symbols
					for (ImportedSymbolInfo importedSymbol : parseResult.symbolTables().get(olfile.toURI()).importedSymbolInfos()) {
						//checking if the symbol is contained in curret symbol name instead of checking if they are equal, as we also want matches that contain our symbol
						if(importedSymbol.name().contains(wordWeAreLookingFor)){
							Value symbol = buildSymbolResponse( importedSymbol.context(), importedSymbol.name());
							symbols.add(symbol);
						}				
					}
					// check the local symbols
					for (LocalSymbolInfo localSymbol : parseResult.symbolTables().get(olfile.toURI()).localSymbols()) {
						if(localSymbol.name().contains(wordWeAreLookingFor)){
							Value symbol = buildSymbolResponse(localSymbol.context(), localSymbol.name());
							symbols.add(symbol);
						}
					}
					modules.add(module);
				} catch( CommandLineException | IOException | CodeCheckException ex) { //Exceptions from the compiler do not matter, as they are found by the fileinspector whenever the file is changed
					System.out.println("Could not search for symbol '"+wordWeAreLookingFor+"' in "+olfile+" . Module contains errors.");
					continue;
				}
			}
			return result;
		} catch( IOException ex) { // An exception happened while reading or opening files in the workspace
			System.out.println("Could not search for symbol '"+wordWeAreLookingFor+"'. An exception happened while reading files in the workspace.\n"+ex.getMessage());
		}
		return result;
	}

	/**
	 * Is used in languageserver/internal/text-document rename call
	 * @param request InspectionToRenameRequest in inspector.ol
	 * @return MoreSymbolsPerModule in inspector.ol
	 * @throws FaultException if any exception occurs all renaming is abandoned, as any errors or problems could lead to wrong renaming
	 * TODO: return a list of all the occourences in all modules to do complete renaming (same problem as in workspaceModuleInspection) when symboltables contain all occurrences
	 */
	@RequestResponse
	public Value inspectionToRename(Value request) throws FaultException {
		System.out.println("Inside inspectionToRename");
		// Get information from request
		String currentFile = request.getFirstChild("textDocument").getFirstChild("uri").strValue();
		int column = request.getFirstChild("position").getFirstChild("character").intValue();
		int line = request.getFirstChild("position").getFirstChild("line").intValue();
		String rootUri = request.getFirstChild("rootUri").strValue();
		String[] includePaths =	request.getChildren( "includePaths" ).stream().map( Value::strValue ).toArray( String[]::new );
		// Create return Value
		Value result = Value.create();

		try {
			// Since the client only provides the file and the position in the file, 
			// we have to figure out which word is at the position
			String wordWeAreLookingFor = findWordWeAreLookingFor(currentFile, column, line, Optional.empty());

			//Get all modules in workspace
			File rootPath = new File(rootUri);
			Stream<Path> allFiles = Files.walk(rootPath.toPath());
			File[] olFiles = allFiles.filter(Files::isRegularFile).filter(path -> path.toString().endsWith(".ol")).map(Path::toFile).toArray( File[]::new );
			allFiles.close();
			ValueVector modules = result.getChildren("module");
			
			try {
				// Get source of the currentFile for the parseResult
				File currentFilePath = new File(currentFile);
				String sourceOfWordWeAreLookingFor = Files.readString(currentFilePath.toPath()); // Read source code in as a string
				final SemanticVerifier parseResult = getModuleInspector( currentFile, Optional.of( sourceOfWordWeAreLookingFor ), includePaths, interpreter() );
				// make module object for the currentFile and its symbols
				Value currentModule = Value.create(currentFilePath.toURI().normalize().toString());
				ValueVector symbols = currentModule.getChildren("symbol");
				// check through local symbols first, to determine if we can simply change it in the current file and all files importing from this
				// or if we have to find the imported module and rename both in the imported module and all other files importing from this
				Boolean localSymbolFound = false;
				for (LocalSymbolInfo localSymbol : parseResult.symbolTables().get(currentFilePath.toURI()).localSymbols()) {
					if(localSymbol.name().equals(wordWeAreLookingFor)){ // the symbol we are renaming is a local symbol to the currentFile
						// Create an entry in the result for this symbol
						// Check if the context from the symbol actually points correctly to the word we are looking for,
						// so we do not rename in the wrong place
						System.out.println("localsymbol context:\n"+localSymbol.context().toString());
						String wordFromContext = getWordFromContext(sourceOfWordWeAreLookingFor, localSymbol.context(), wordWeAreLookingFor);
						if(wordFromContext.equals(wordWeAreLookingFor)){ // the rename will happen in the correct place, so we create symbol object
							Value symbol = buildSymbolResponse(localSymbol.context(), localSymbol.name());
							symbols.add(symbol);
							modules.add(currentModule);
						} else{ // the symbol cannot be renamed correctly, throw error and do not rename anything
							throw new FaultException( "Rename abandoned. '"+wordWeAreLookingFor+"' exists in file: "+currentFile+". '"+wordWeAreLookingFor+"' could however not be located and renamed correctly. The user is required to do this manually if the renaming is still wanted." );
						}
						localSymbolFound = true;
						for (File olfile : olFiles) { // go through all files in workspace and check if it has been imported anywhere
							String source = Files.readString(olfile.toPath());
							final SemanticVerifier parseResultForLoop = getModuleInspector( olfile.toString(), Optional.of( source ), includePaths, interpreter() );
							// create module object for each olfile
							Value module = Value.create(olfile.toString());
							ValueVector olfileSymbols = module.getChildren("symbol");
							//check the only the imported symbols
							for (ImportedSymbolInfo importedSymbol : parseResultForLoop.symbolTables().get(olfile.toURI()).importedSymbolInfos()) {
								// The symbol has been imported. The second check is to determine if the symbol is from currentFile or if another imported module has the same name for a symbol
								if(importedSymbol.name().equals(wordWeAreLookingFor) && importedSymbol.node().context().source().equals(currentFilePath.toURI().normalize())){
									// Check if the context from the symbol actually points correctly to the word we are looking for,
									// so we do not rename in the wrong place
									String wordFromContext1 = getWordFromContext(source, importedSymbol.context(), wordWeAreLookingFor);
									if(wordFromContext1.equals(wordWeAreLookingFor)){
										Value symbol = buildSymbolResponse(importedSymbol.context(), importedSymbol.name());
										olfileSymbols.add(symbol);
									} else{
										throw new FaultException( "Rename abandoned. '"+wordWeAreLookingFor+"' exists in file: "+olfile.toString()+". '"+wordWeAreLookingFor+"' could however not be located and renamed correctly. The user is required to do this manually if the renaming is still wanted." );
									}
									
								}
							}modules.add(module);
						}
					}
				}
				// if the symbol we are renaming is not local to currentFile we check through imported symbols
				if(!localSymbolFound){
					for(ImportedSymbolInfo currentFileImportedSymbol : parseResult.symbolTables().get(currentFilePath.toURI()).importedSymbolInfos()){
						if(currentFileImportedSymbol.name().equals(wordWeAreLookingFor)){ // the symbol is imported
							URI importedFileURI = currentFileImportedSymbol.node().context().source(); // get the original module
							// check it is not a module imported from the compiler, as we should rename anything related to modules from the compiler
							if(importedFileURI.normalize().toString().contains(rootUri)){
								// Check if the context from the symbol actually points correctly to the word we are looking for,
								// so we do not rename in the wrong place
								String wordFromContext = getWordFromContext(sourceOfWordWeAreLookingFor, currentFileImportedSymbol.context(), wordWeAreLookingFor);
								if(wordFromContext.equals(wordWeAreLookingFor)){
									Value symbol = buildSymbolResponse(currentFileImportedSymbol.context(), currentFileImportedSymbol.name());
									symbols.add(symbol);
									modules.add(currentModule);
								} else{
									throw new FaultException( "Rename abandoned. '"+wordWeAreLookingFor+"' exists in file: "+currentFile+". '"+wordWeAreLookingFor+"' could however not be located and renamed correctly. The user is required to do this manually if the renaming is still wanted." );
								}
								// Check if the context from the symbol actually points correctly to the word we are looking for,
								// so we do not rename in the wrong place
								File importedFile = new File(importedFileURI.normalize().toString());
								String importedSource = Files.readString(importedFile.toPath());
								String importedWordFromContext = getWordFromContext(importedSource, currentFileImportedSymbol.node().context(), wordWeAreLookingFor);
								if(importedWordFromContext.equals(wordWeAreLookingFor)){		
									Value module = Value.create(importedFile.toString());
									ValueVector importedFileSymbols = module.getChildren("symbol");
									Value symbol = buildSymbolResponse(currentFileImportedSymbol.node().context(), currentFileImportedSymbol.name());
									importedFileSymbols.add(symbol);
									modules.add(module);
								} else{
									throw new FaultException( "Rename abandoned. '"+wordWeAreLookingFor+"' exists in file: "+importedFile.toString()+". '"+wordWeAreLookingFor+"' could however not be located and renamed correctly. The user is required to do this manually if the renaming is still wanted." );
								}

								// Go through all other files in workspace and check if they are importing this symbol so they can also be renamed
								for (File olfile : olFiles) {
									String source = Files.readString(olfile.toPath());
									final SemanticVerifier parseResultForLoop = getModuleInspector( olfile.toString(), Optional.of( source ), includePaths, interpreter() );
									//check if the symbol is imported first		
									Value module = Value.create(olfile.toString());
									ValueVector olfileSymbols = module.getChildren("symbol");
									for (ImportedSymbolInfo importedSymbol : parseResultForLoop.symbolTables().get(olfile.toURI()).importedSymbolInfos()) {
										if(importedSymbol.name().equals(wordWeAreLookingFor) && importedSymbol.node().context().source().equals(importedFileURI.normalize())){
											String wordFromContext1 = getWordFromContext(source, importedSymbol.node().context(), wordWeAreLookingFor);
											if(wordFromContext1.equals(wordWeAreLookingFor)){
												Value symbol = buildSymbolResponse(importedSymbol.node().context(), importedSymbol.name());
												olfileSymbols.add(symbol);
											} else{
												throw new FaultException( "Rename abandoned. '"+wordWeAreLookingFor+"' exists in file: "+importedFile.toString()+". '"+wordWeAreLookingFor+"' could however not be located and renamed correctly. The user is required to do this manually if the renaming is still wanted." );
											}
										}
									}
									modules.add(module);
								}
							}
						}
					}
				}
				return result;
			} catch (IOException ex) { // e.g. if one of the files could not be read
				throw new FaultException("Rename abandoned.", ex);
			}
		} catch (Exception ex){
			if(!ex.getMessage().contains("Rename abandoned")){ //Will catch errors from inner try-catch statement as well
				throw new FaultException("Rename abandoned. "+ex.getMessage());
			} else {
				throw new FaultException(ex.getMessage());
			}
		}
	}

	/**
	 * Some calls from the client only provide the position in the current file
	 * and therefore we need to manually determine what the word we are looking for is
	 * @param currentFile
	 * @param column
	 * @param line
	 * @param optinalSource
	 * @return
	 * @throws IOException
	 */
	private String findWordWeAreLookingFor(String currentFile, int column, int line, Optional<String> optinalSource) throws IOException{
		String wordWeAreLookingFor;
		// Get the source code of the file
		File currentFilePath = new File(currentFile);
		String sourceOfWordWeAreLookingFor;
		if(optinalSource.isPresent()){ // the source code has already been read and is provided by the caller
			sourceOfWordWeAreLookingFor = optinalSource.get();
		} else { // the source code is not provided, read it in
			sourceOfWordWeAreLookingFor = Files.readString(currentFilePath.toPath()); // Read source code in as a string
		}
		String[] codeLines = sourceOfWordWeAreLookingFor.lines().toArray(String[]::new); //Split source into lines
		String correctLine = codeLines[line].stripTrailing(); // get the line from the position
		String beforeCourser = correctLine.substring(0, column).stripTrailing(); //get part of line before coursor
		String[] splitByNonLetter = beforeCourser.split("[\\W]"); //split the part before the coursor by non letters
		// Go through the split parts before the coursor to find the start index of the word we are looking for
		int startOfWord = 0;
		for (int i = 0; i < splitByNonLetter.length-1; i++) {
			if(splitByNonLetter[i].length() == 0){ // We add 1 when we are looking at a 0 length split, as this is a nonletter with no sorrounding letters
				startOfWord += 1;
			} else { // add the length of the split, and if it is not the last split and the next part has length >=1, also add 1 for the nonletter character
				startOfWord += splitByNonLetter[i].length();
				if( (i+1) < splitByNonLetter.length ){
					if(splitByNonLetter[i+1].length() >=1){
						startOfWord += 1;
					}
				}
			}
		}
		String lineStartOfWord = correctLine.substring(startOfWord).trim(); // Get rest of the line, from where the word starts
		if(lineStartOfWord.matches("^[\\w]+[\\W]+.*$")){ // if it matches a character or word followed by one or more non letters and 0 or more characters
			wordWeAreLookingFor = lineStartOfWord.split("[^\\w]")[0]; // the first split contains the word
		} else {
			wordWeAreLookingFor = lineStartOfWord; //otherwise all of lineStartOfWord is the word
		}
		return wordWeAreLookingFor;
	}

	/**
	 * Used for checking if a symbol we are looking for matches the word we find
	 * by using the symbol context to look at the source by the startcolumn and startline
	 * @param source
	 * @param context
	 * @param wordWeAreLookingFor
	 * @return
	 */
	private String getWordFromContext(String source, ParsingContext context, String wordWeAreLookingFor){
		try {
			String[] lines = source.lines().toArray(String[]::new); // split the source into lines
			String lineString = lines[context.startLine()]; // get the line of source
			// get the part of text that starts at the column and ends column+length(wordWeAreLookingFor)
			String wordFromContext = lineString.substring(context.startColumn(), context.startColumn() + wordWeAreLookingFor.length());
			return wordFromContext;	
		} catch (IndexOutOfBoundsException e) { // if the line or column causes an IndexOutOfBoundsException then we cannot rename this symbol
			return ""; // the empty string will cause an error by the caller
		}
	}
    
	@RequestResponse
	public Value inspectPorts( Value request ) throws FaultException {
		try {
			final ProgramInspector inspector;
			String[] includePaths =
				request.getChildren( "includePaths" ).stream().map( Value::strValue ).toArray( String[]::new );
			if( request.hasChildren( "source" ) ) {
				inspector = getInspector( request.getFirstChild( "filename" ).strValue(),
					Optional.of( request.getFirstChild( "source" ).strValue() ), includePaths, interpreter() );
			} else {
				inspector =
					getInspector( request.getFirstChild( "filename" ).strValue(), Optional.empty(), includePaths,
						interpreter() );
			}
			return buildFileInspectionResponse( inspector );
		} catch( CommandLineException | IOException | ParserException | ModuleException ex ) {
			throw new FaultException( ex );
		} catch( CodeCheckException ex ) {
			throw new FaultException(
				"SemanticException",
				ex.getMessage() );
		}
	}

	@RequestResponse
	public Value inspectTypes( Value request ) throws FaultException {
		String[] includePaths =
			request.getChildren( "includePaths" ).stream().map( Value::strValue ).toArray( String[]::new );
		try {
			ProgramInspector inspector =
				getInspector( request.getFirstChild( "filename" ).strValue(), Optional.empty(), includePaths,
					interpreter() );
			return buildProgramTypeInfo( inspector );
		} catch( CommandLineException | IOException | ParserException | ModuleException ex ) {
			throw new FaultException( ex );
		} catch( CodeCheckException ex ) {
			throw new FaultException(
				"SemanticException",
				ex.getMessage() );
		}
	}

	/**
	 * Used for returning the inspector from compiling the code
	 * @param filename
	 * @param source
	 * @param includePaths
	 * @param interpreter
	 * @return
	 * @throws CommandLineException
	 * @throws IOException
	 * @throws CodeCheckException
	 */
	private static ProgramInspector getInspector( String filename, Optional< String > source, String[] includePaths,
		Interpreter interpreter )
		throws CommandLineException, IOException, CodeCheckException {
		String[] args = { filename };
		try(
			CommandLineParser cmdParser =
						new CommandLineParser(args, Inspector.class.getClassLoader())) {
			Interpreter.Configuration interpreterConfiguration = cmdParser.getInterpreterConfiguration();
			SemanticVerifier.Configuration configuration = new SemanticVerifier.Configuration(
					interpreterConfiguration.executionTarget());
			configuration.setCheckForMain(false);
			final ModuleSource ms;
			if (source.isPresent()) {
				ms = ModuleSource.create(interpreterConfiguration.source().uri(),
						new ByteArrayInputStream(source.get().getBytes()), ServiceNode.DEFAULT_MAIN_SERVICE_NAME);
			} else {
				ms = interpreterConfiguration.source();
			}
			Program program = ParsingUtils.parseProgram(
					ms,
					interpreterConfiguration.charset(),
					includePaths,
					// interpreterConfiguration.packagePaths(),
					interpreter.configuration().packagePaths(), // TODO make this a parameter from the Jolie request
					interpreterConfiguration.jolieClassLoader(),
					interpreterConfiguration.constants(),
					configuration,
					true);
			return ParsingUtils.createInspector(program);
		}
	}

	/**
	 * Used for returning the map of symboltables from compiling the source code
	 * @param filename
	 * @param source
	 * @param includePaths
	 * @param interpreter
	 * @return
	 * @throws CommandLineException
	 * @throws IOException
	 * @throws CodeCheckException
	 */
	public static SemanticVerifier getModuleInspector( String filename, Optional< String > source, String[] includePaths,
		Interpreter interpreter )
		throws CommandLineException, IOException, CodeCheckException {
		String[] args = { filename };
		try(
			CommandLineParser cmdParser =
						new CommandLineParser(args, Inspector.class.getClassLoader())) {
			Interpreter.Configuration interpreterConfiguration = cmdParser.getInterpreterConfiguration();
			SemanticVerifier.Configuration configuration = new SemanticVerifier.Configuration(
					interpreterConfiguration.executionTarget());
			configuration.setCheckForMain(false);
			final ModuleSource ms;
			if (source.isPresent()) {
				ms = ModuleSource.create(interpreterConfiguration.source().uri(),
						new ByteArrayInputStream(source.get().getBytes()), ServiceNode.DEFAULT_MAIN_SERVICE_NAME);
			} else {
				ms = interpreterConfiguration.source();
			}
			SemanticVerifier semanticVerifierResult = ParsingUtils.parseProgramModule(
					ms,
					interpreterConfiguration.charset(),
					includePaths,
					// interpreterConfiguration.packagePaths(),
					interpreter.configuration().packagePaths(), // TODO make this a parameter from the Jolie request
					interpreterConfiguration.jolieClassLoader(),
					interpreterConfiguration.constants(),
					configuration,
					true);
			return semanticVerifierResult;
		}
	}

	/**
	 * Used for helping to create ModuleInspectionResponse
	 * @param uri
	 * @param context
	 * @param symbolName
	 * @return value containing context and symbol name
	 */
	private static Value buildSymbolResponse( ParsingContext context, String symbolName){
		Value symbol = Value.create(symbolName);
		Value valueContext = Value.create();
		valueContext.getNewChild("startLine").setValue(context.startLine());
		valueContext.getNewChild("endLine").setValue(context.startLine());
		valueContext.getNewChild("startColumn").setValue(context.startColumn());
		valueContext.getNewChild("endColumn").setValue(context.startColumn()+symbolName.length());
		symbol.getNewChild("context").deepCopy(valueContext);
		return symbol;
	}
	private static Value buildSymbolResponse(String uri, ParsingContext context, String symbolName){
		Value module = Value.create(uri);
		Value valueContext = Value.create();
		valueContext.getNewChild("startLine").setValue(context.startLine());
		valueContext.getNewChild("endLine").setValue(context.startLine());
		valueContext.getNewChild("startColumn").setValue(context.startColumn());
		valueContext.getNewChild("endColumn").setValue(context.startColumn()+symbolName.length());
		module.getNewChild("context").deepCopy(valueContext);
		module.getNewChild("name").add(Value.create(symbolName));
		return module;
	}
    
	private static Value buildFileInspectionResponse( ProgramInspector inspector ) {
		Value result = Value.create();
		ValueVector inputPorts = result.getChildren( FileInspectionResponse.INPUT_PORT );
		ValueVector outputPorts = result.getChildren( FileInspectionResponse.OUTPUT_PORT );
		ValueVector referredTypesValues = result.getChildren( FileInspectionResponse.REFERRED_TYPES );

		Set< String > referredTypes = new HashSet<>();
		for( InputPortInfo portInfo : inspector.getInputPorts() ) {
			inputPorts.add( buildPortInfo( portInfo, inspector, referredTypes ) );
		}

		for( OutputPortInfo portInfo : inspector.getOutputPorts() ) {
			outputPorts.add( buildPortInfo( portInfo, referredTypes ) );
		}

		Map< String, TypeDefinition > types = new HashMap<>();
		for( TypeDefinition t : inspector.getTypes() ) {
			types.put( t.name(), t );
		}

		referredTypes.stream().filter( types::containsKey )
			.forEach( typeName -> referredTypesValues.add( buildTypeDefinition( types.get( typeName ) ) ) );

		return result;
	}

	private static Value buildPortInspectionResponse( ProgramInspector inspector ) {
		Value result = Value.create();
		ValueVector inputPorts = result.getChildren( PortInspectionResponse.INPUT_PORT );
		ValueVector outputPorts = result.getChildren( PortInspectionResponse.OUTPUT_PORT );
		ValueVector referredTypesValues = result.getChildren( PortInspectionResponse.REFERRED_TYPES );

		Set< String > referredTypes = new HashSet<>();
		for( InputPortInfo portInfo : inspector.getInputPorts() ) {
			inputPorts.add( buildPortInfo( portInfo, inspector, referredTypes ) );
		}

		for( OutputPortInfo portInfo : inspector.getOutputPorts() ) {
			outputPorts.add( buildPortInfo( portInfo, referredTypes ) );
		}

		Map< String, TypeDefinition > types = new HashMap<>();
		for( TypeDefinition t : inspector.getTypes() ) {
			types.put( t.name(), t );
		}

		referredTypes.stream().filter( types::containsKey )
			.forEach( typeName -> referredTypesValues.add( buildTypeDefinition( types.get( typeName ) ) ) );

		return result;
	}

	private static Value buildTypeDefinition( TypeDefinition typeDef ) {
		Value result = Value.create();
		result.setFirstChild( TypeDefinitionInfoType.NAME, typeDef.name() );
		result.getChildren( TypeDefinitionInfoType.TYPE ).add( buildTypeInfo( typeDef ) );
		return result;
	}

	private static Value buildProgramTypeInfo( ProgramInspector inspector ) {
		Value returnValue = Value.create();
		ValueVector types = ValueVector.create();
		returnValue.children().put( "types", types );
		for( TypeDefinition type : inspector.getTypes() ) {
			Value typeDefinition = Value.create();
			typeDefinition.setFirstChild( TypeDefinitionInfoType.NAME, type.name() );
			typeDefinition.getChildren( TypeDefinitionInfoType.TYPE ).add( buildTypeInfo( type ) );
			types.add( typeDefinition );
		}
		return returnValue;
	}

	private static Value buildPortInfo( InputPortInfo portInfo, ProgramInspector inspector,
		Set< String > referredTypesSet ) {
		Value result = Value.create();
		result.setFirstChild( PortInfoType.NAME, portInfo.id() );

		if( portInfo.location() != null ) {
			result.setFirstChild( PortInfoType.LOCATION, portInfo.location().toString() );
		}
		if( portInfo.protocol() != null ) {
			result.setFirstChild( PortInfoType.PROTOCOL, portInfo.protocolId() );
		}
		portInfo.getDocumentation().ifPresent( doc -> result.setFirstChild( PortInfoType.DOCUMENTATION, doc ) );

		ValueVector interfaces = result.getChildren( PortInfoType.INTERFACE );

		portInfo.getInterfaceList().forEach( i -> interfaces.add( buildInterfaceInfo( i, referredTypesSet ) ) );

		getAggregatedInterfaces( portInfo, inspector )
			.forEach( i -> interfaces.add( buildInterfaceInfo( i, referredTypesSet ) ) );

		return result;
	}

	private static ArrayList< InterfaceDefinition > getAggregatedInterfaces( InputPortInfo portInfo,
		ProgramInspector inspector ) {
		ArrayList< InterfaceDefinition > returnList = new ArrayList<>();
		for( InputPortInfo.AggregationItemInfo aggregationItemInfo : portInfo.aggregationList() ) {
			for( String outputPortName : aggregationItemInfo.outputPortList() ) {
				OutputPortInfo outputPortInfo = Arrays.stream( inspector.getOutputPorts() )
					.filter( ( outputPort ) -> outputPort.id().equals( outputPortName ) )
					.findFirst().get();
				outputPortInfo.getInterfaceList().forEach( ( aggregatedInterfaceInfo ) -> returnList.add(
					Interfaces.extend( aggregatedInterfaceInfo, aggregationItemInfo.interfaceExtender(),
						portInfo.id() ) ) );
			}
		}
		return returnList;
	}

	private static Value buildPortInfo( OutputPortInfo portInfo, Set< String > referredTypesSet ) {
		Value result = Value.create();
		result.setFirstChild( PortInfoType.NAME, portInfo.id() );

		if( portInfo.location() != null ) {
			result.setFirstChild( PortInfoType.LOCATION, portInfo.location().toString() );
		}
		if( portInfo.protocol() != null ) {
			result.setFirstChild( PortInfoType.PROTOCOL, portInfo.protocolId() );
		}
		portInfo.getDocumentation().ifPresent( doc -> result.setFirstChild( PortInfoType.DOCUMENTATION, doc ) );

		ValueVector interfaces = result.getChildren( PortInfoType.INTERFACE );

		portInfo.getInterfaceList().forEach( i -> interfaces.add( buildInterfaceInfo( i, referredTypesSet ) ) );

		return result;
	}

	private static Value buildInterfaceInfo( InterfaceDefinition interfaceDefinition, Set< String > referredTypesSet ) {
		Value result = Value.create();
		result.setFirstChild( InterfaceInfoType.NAME, interfaceDefinition.name() );
		interfaceDefinition.getDocumentation()
			.ifPresent( doc -> result.setFirstChild( InterfaceInfoType.DOCUMENTATION, doc ) );
		ValueVector operations = result.getChildren( InterfaceInfoType.OPERATION );
		interfaceDefinition.operationsMap().entrySet()
			.forEach( o -> operations.add( buildOperationInfo( o.getValue(), referredTypesSet ) ) );
		return result;
	}

	private static Value buildOperationInfo( OperationDeclaration operationDeclaration,
		Set< String > referredTypesSet ) {
		Value result = Value.create();
		result.setFirstChild( OperationInfoType.NAME, operationDeclaration.id() );
		operationDeclaration.getDocumentation()
			.ifPresent( doc -> result.setFirstChild( OperationInfoType.DOCUMENTATION, doc ) );
		if( operationDeclaration instanceof RequestResponseOperationDeclaration ) {
			RequestResponseOperationDeclaration rrod = (RequestResponseOperationDeclaration) operationDeclaration;
			result.setFirstChild( OperationInfoType.REQUEST_TYPE, rrod.requestType().name() );
			referredTypesSet.add( rrod.requestType().name() );
			result.setFirstChild( OperationInfoType.RESPONSE_TYPE, rrod.responseType().name() );
			referredTypesSet.add( rrod.responseType().name() );
			if( !rrod.faults().isEmpty() ) {
				ValueVector faults = result.getChildren( OperationInfoType.FAULT );
				rrod.faults().forEach( ( faultName, faultType ) -> {
					Value faultInfo = Value.create();
					faultInfo.setFirstChild( FaultInfoType.NAME, faultName );
					faultInfo.setFirstChild( FaultInfoType.TYPE, faultType.name() );
					faults.add( faultInfo );
					referredTypesSet.add( faultType.name() );
				} );
			}
		} else {
			OneWayOperationDeclaration owd = (OneWayOperationDeclaration) operationDeclaration;
			result.setFirstChild( OperationInfoType.REQUEST_TYPE, owd.requestType().name() );
			referredTypesSet.add( owd.requestType().name() );
		}
		return result;
	}

	private static Value buildTypeInfo( TypeDefinition t ) {
		Value result = Value.create();
		t.getDocumentation().ifPresent( doc -> result.setFirstChild( TypeInfoType.DOCUMENTATION, doc ) );

		if( t instanceof TypeDefinitionLink ) {
			result.setFirstChild( TypeInfoType.LINKED_TYPE_NAME, ((TypeDefinitionLink) t).linkedTypeName() );
		} else if( t instanceof TypeChoiceDefinition ) {
			TypeChoiceDefinition tc = (TypeChoiceDefinition) t;
			result.getChildren( TypeInfoType.LEFT ).add( buildTypeInfo( tc.left() ) );
			result.getChildren( TypeInfoType.RIGHT ).add( buildTypeInfo( tc.right() ) );
		} else if( t instanceof TypeInlineDefinition ) {
			TypeInlineDefinition ti = (TypeInlineDefinition) t;
			result.setFirstChild( TypeInfoType.NATIVE_TYPE, ti.basicType().nativeType().id() );
			result.setFirstChild( TypeInfoType.UNTYPED_FIELDS, ti.untypedSubTypes() );
			if( ti.hasSubTypes() ) {
				ValueVector fields = result.getChildren( TypeInfoType.FIELDS );
				ti.subTypes().forEach( entry -> {
					Value field = Value.create();
					field.setFirstChild( FieldType.NAME, entry.getKey() );

					Value range = field.getFirstChild( FieldType.RANGE );
					range.setFirstChild( FieldType.MIN, entry.getValue().cardinality().min() );
					range.setFirstChild( FieldType.MAX, entry.getValue().cardinality().max() );

					field.getChildren( FieldType.TYPE ).add( buildTypeInfo( entry.getValue() ) );

					fields.add( field );
				} );
			}
		}

		return result;
	} 
}
