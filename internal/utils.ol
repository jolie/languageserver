/* MIT License
 *
 * Copyright (c) 2021 The Jolie Programming Language
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
from console import Console
from string_utils import StringUtils
from runtime import Runtime
from file import File
from inspector import Inspector
from ..lsp import UtilsInterface, ServerToClient, InspectionUtilsInterface

constants {
	INTEGER_MAX_VALUE = 2147483647
}

/*
 * The main aim of this service is to keep saved
 * in global.textDocument all open documents
 * and keep them updated. The type of global.textDocument
 * is TextDocument and it is defined in types/lsp.iol
 */
service Utils {
	execution: sequential

	embed Inspector as Inspector
	embed Console as Console
	embed StringUtils as StringUtils
	embed Runtime as Runtime
	embed File as File

	inputPort Utils {
		location: "local://Utils"
		interfaces: UtilsInterface
	}

	outputPort LanguageClient {
		location: "local://Client"
		interfaces: ServerToClient
	}

	outputPort InspectionUtils {
		location: "local://InspectionUtils"
		interfaces: InspectionUtilsInterface
	}

	init {
		println@Console( "Utils Service started at " + global.inputPorts.Utils.location + ", connected to " + LanguageClient.location )(  )
	}

	main {
		[ insertNewDocument( newDoc ) ] {
			docText -> newDoc.textDocument.text
			uri -> newDoc.textDocument.uri
			version -> newDoc.textDocument.version
			splitReq = docText
			splitReq.regex = "\n"
			split@StringUtils( splitReq )( splitRes )
			for ( line in splitRes.result ) {
				doc.lines[#doc.lines] = line
			}
			documentData << {
				uri = uri
				text = docText
			}

			println@Console("Inside insertNewDocument")()
			inspectDocument@InspectionUtils(documentData)(inspectionResult)
			if(is_defined(inspectionResult)){
				doc.jolieProgram << inspectionResult
			}
			doc << {
				uri = uri
				source = docText
				version = version
			}

			println@Console( "Insert new document: " + doc.uri )()

			// TODO: use a dictionary with URIs as keys instead of an array
			global.textDocument[#global.textDocument] << doc
		}

		[ updateDocument( txtDocModifications ) ] {
			docText -> txtDocModifications.text
			uri -> txtDocModifications.uri
			newVersion -> txtDocModifications.version
			docsSaved -> global.textDocument
			found = false
			for ( i = 0, i < #docsSaved && !found, i++ ) {
				if ( docsSaved[i].uri == uri ) {
					found = true
					indexDoc = i
				}
			}
			//TODO is found == false, throw ex (should never happen though)
			if ( found && docsSaved[indexDoc].version < newVersion ) {
				splitReq = docText
				splitReq.regex = "\n"
				split@StringUtils( splitReq )( splitRes )
				for ( line in splitRes.result ) {
					doc.lines[#doc.lines] = line
				}
				documentData << {
					uri = uri
					text = docText
				}
				
				println@Console("Inside updateDocument")()
				inspectDocument@InspectionUtils(documentData)(inspectionResult)
				if(is_defined(inspectionResult)){
					doc.jolieProgram << inspectionResult
				}
				doc << {
					source = docText
					version = newVersion
				}

				docsSaved[indexDoc] << doc
			} else {
				documentData << {
					uri = uri
					text = docText
				}
				println@Console("Inside updateDocument, else")()
				inspectDocument@InspectionUtils(documentData)(inspectionResult)
			}
		}

		[ deleteDocument( txtDocParams ) ] {
			uri -> txtDocParams.textDocument.uri
			docsSaved -> global.textDocument
			keepRunning = true
			for ( i = 0, i < #docsSaved && keepRunning, i++ ) {
				if ( uri == docsSaved[i].uri ) {
				undef( docsSaved[i] )
				keepRunning = false
				}
			}
		}

		[ getDocument( uri )( txtDocument ) {
			docsSaved -> global.textDocument
			found = false
			for ( i = 0, i < #docsSaved && !found, i++ ) {
				println@Console( " Checking " + docsSaved[i].uri )()
				if ( docsSaved[i].uri == uri ) {
					txtDocument << docsSaved[i]
					found = true
				}
			}

			if ( !found ) {
				//TODO if found == false throw exception
				println@Console( "Doc not found: " + uri )()
			}
		}]
	}
}
