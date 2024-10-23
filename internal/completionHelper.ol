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
from ..inspectorJavaService.pathsInJolie import PathsInJolie
from ..lsp import CompletionHelperInterface

constants {
	CompletionItemKind_Text = 1,
	CompletionItemKind_Method = 2,
	CompletionItemKind_Function = 3,
	CompletionItemKind_Constructor = 4,
	CompletionItemKind_Field = 5,
	CompletionItemKind_Variable = 6,
	CompletionItemKind_Class = 7,
	CompletionItemKind_Interface = 8,
	CompletionItemKind_Module = 9,
	CompletionItemKind_Property = 10,
	CompletionItemKind_Unit = 11,
	CompletionItemKind_Value = 12,
	CompletionItemKind_Enum = 13,
	CompletionItemKind_Keyword = 14,
	CompletionItemKind_Snippet = 15,
	CompletionItemKind_Color = 16,
	CompletionItemKind_File = 17,
	CompletionItemKind_Reference = 18,
	CompletionItemKind_Folder = 19,
	CompletionItemKind_EnumMember = 20,
	CompletionItemKind_Constant = 21,
	CompletionItemKind_Struct = 22,
	CompletionItemKind_Event = 23,
	CompletionItemKind_Operator = 24,
	CompletionItemKind_TypeParameter = 25
}

service CompletionHelper {
	execution: concurrent

	embed Console as Console
	embed StringUtils as StringUtils
	embed PathsInJolie as PathsInJolie

	inputPort CompletionHelper{
		location: "local://CompletionHelper"
		interfaces: CompletionHelperInterface
	}

	init{
		global.keywordSnippets << {
			snippet[0] = "outputPort"
			snippet[0].body = "outputPort ${1:PortName} {\n\tlocation: $2\n\tprotocol: $3\n\tinterfaces: $4\n}"
			snippet[1] = "inputPort"
			snippet[1].body = "inputPort ${1:PortName} {\n\tlocation: $2\n\tprotocol: $3\n\tinterfaces: $4\n}"
			snippet[2] = "interface"
			snippet[2].body = "interface ${1:interfaceName} {\n\tRequestResponse: $2\n\tOneWay: $3\n}"
			snippet[3] = "main"
			snippet[3].body = "main\n{\n\t$0\n}"
			snippet[4] = "init"
			snippet[4].body = "init\n{\n\t$0\n}"
			snippet[5] = "constants"
			snippet[5].body = "constants {\n\t${1:constantName} = ${2:value}"
			snippet[6] = "include"
			snippet[6].body = "include \"${1:file}\"\n$0"
			snippet[7] = "while"
			snippet[7].body = "while ( ${1:condition} ) {\n\t$2\n}"
			snippet[8] = "undef"
			snippet[8].body = "undef ( ${0:variableName} )"
			snippet[9] = "type (basic)"
			snippet[9].body = "type ${1:typeName}: ${2:basicType}"
			snippet[10] = "type (choice)"
			snippet[10].body = "type ${1:typeName}: ${2:Type1} | ${3:Type2}"
			snippet[11] = "type (custom)"
			snippet[11].body = "type ${1:typeName}: ${2:rootType} {\n\t${3:subNodeName}: ${4:subNodeType}\n}"
			snippet[12] = "throws"
			snippet[12].body = "throws ${1:faultName}( ${2:faultType} )"
			snippet[13] = "throw"
			snippet[13].body = "throw( ${0:error} )"
			snippet[14] = "synchronized"
			snippet[14].body = "synchronized( ${1:token} ) {\n\t$2\n}"
			snippet[15] = "redirects"
			snippet[15].body = "Redirects: ${1:resourceName} => ${2:outputPortName}"
			snippet[16] = "provide"
			snippet[16].body = "provide\n\t${1:inputChoice}\nuntil\n\t${2:inputChoice}"
			snippet[17] = "is_defined"
			snippet[17].body = "is_defined( ${0:variableName} )"
			snippet[18] = "instanceof"
			snippet[18].body = "instanceof ${0:type}"
			snippet[19] = "install"
			snippet[19].body = "install( ${1:faultName} => ${2:faultCode} )"
			snippet[20] = "if"
			snippet[20].body = "if ( ${1:codition} ) {\n\t$2\n}"
			snippet[21] = "else"
			snippet[21].body = "else {\n\t$0\n}"
			snippet[22] = "else if"
			snippet[22].body = "else if ( ${0:condition} ) {\n\t$1\n}"
			snippet[23] = "foreach element"
			snippet[23].body = "for ( ${1:element} in ${2:array} ) {\n\t$3\n}"
			snippet[24] = "foreach"
			snippet[24].body = "foreach ( ${1:child} : ${2:parent} ) {\n\t$3\n}"
			snippet[25] = "for"
			snippet[25].body = "for ( ${1:init}, ${2:cond}, ${3:afterthought} ) {\n\t$4\n}"
			snippet[26] = "global"
			snippet[26].body = "global.${0:varName}"
			snippet[27] = "execution"
			snippet[27].body = "execution{ ${0:single|concurrent|sequential} }"
			snippet[28] = "define"
			snippet[28].body = "define ${1:procedureName}\n{\n\t$2\n}"
			snippet[29] = "embedded"
			snippet[29].body = "embedded {\n\t{1:Language}: \"${2:file_path}\" in ${3:PortName}\n}"
			//TODO dynamic embedding
			snippet[30] = "cset"
			snippet[30].body = "cset {\n\t${1:correlationVariable}: ${2:alias}\n}"
			snippet[31] = "aggregates"
			snippet[31].body = "Aggregates: ${0:outputPortName}"
			snippet[32] = "from"
			snippet[32].body = "from ${0:module} import ${1:symbols}"
		}
	}

	main{
		/*
		* Tries to find a possible completion as if the request is for an operation
		* @Request CompletionOperationRequest from lsp.ol
		* @Response CompletionOperationResponse from lsp.ol
		*/
		[completionOperation(request)(response){
			for ( port in request.jolieProgram.outputPorts ) {
				for ( iFace in port.interfaces ) {
					for ( op in iFace.operations ) {
						if ( !is_defined( triggerChar ) ) {
							//was not '@' to trigger the completion
							contains@StringUtils( op.name {substring = request.codeLine} )( operationFound ) // TODO: fuzzy search
							undef( temp )
							if ( operationFound ) {
								snippet = op.name + "@" + port.name
								label = snippet
								kind = CompletionItemKind_Method
							}
						} else {
							//@ triggered the completion
							operationFound = ( op.name == request.codeLine )
							label = port.name
							snippet = label
							kind = CompletionItemKind_Class
						}

						if ( operationFound ) {
							//build the rest of the snippet to be sent
							if ( is_defined( op.responseType ) ) {
								//is a reqRes operation
								reqVar = op.requestType.name
								resVar = op.responseType.name
								if ( resVar == NATIVE_TYPE_VOID ) {
									resVar = ""
								}
								snippet += "( ${1:" + reqVar + "} )( ${2:" + resVar + "} )"
							} else {
								//is a OneWay operation
								notificationVar = op.requestType.name
								snippet = "( ${1:" + notificationVar + "} )"
							}
							
							//build the completionItem
							portFound = true
							completionItem << {
								label = label
								kind = kind
								insertTextFormat = 2
								insertText = snippet
							}
							response.result[#response.result] << completionItem
						}
					}
				}
			}
		}]

		/*
		* Tries to find a possible completion as if the request is for a keyword
		* @Request CompletionKeywordRequest from lsp.ol
		* @Response CompletionKeywordResponse from lsp.ol
		*/
		[completionKeywords(request)(response){
			//loop for completing reservedWords completion
			//for (kewyword in global.keywordSnippets.snippet)
			//doesn't work, used a classic for with counter
			keyword -> global.keywordSnippets
			for ( i=0, i<#keyword.snippet, i++ ) {
				contains@StringUtils( keyword.snippet[i] {
					substring = request.codeLine
				} )( keywordFound )
				
				if ( keywordFound ) {
					item << {
						label = keyword.snippet[i]
						kind = 14
						insertTextFormat = 2
						insertText = keyword.snippet[i].body
					}
					response.result[#response.result] << item
				}
			}
		}]

		/*
		* Completion for import module
		* @Request CompletionImportModuleRequest from lsp.ol
		* @Response CompletionImportModuleResponse from lsp.ol
		*/
		[completionImportModule(request)(response){
			// calls helper function from java to inspect path from the import module
			inspectPackagePath@PathsInJolie({joliePackagePath = request.regexMatch[1], sourcePath = request.txtDocUri })(inspectResponse)
			response.result << inspectResponse.possiblePackages
		}]

		/*
		* Completion for import symbol
		* @Request CompletionImportSymbolRequest from lsp.ol
		* @Response CompletionImportSymbolResponse from lsp.ol
		*/
		[completionImportSymbol(request)(response){
			// calls helper function from java to inspect the symbol
			inspectSymbol@PathsInJolie({packagePath = request.regexMatch[1], symbol = request.regexMatch[2], sourcePath = request.txtDocUri })(inspectResponse)
			response.result << inspectResponse.possibleSymbols
		}]
	}
}
