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
from math import Math
from ..inspectorJavaService.inspector import Inspector, CodeCheckExceptionType
from ..lsp import ServerToClient, InspectionUtilsInterface

constants {
	INTEGER_MAX_VALUE = 2147483647
}

service InspectionUtils {
	execution: sequential

	embed Inspector as Inspector
	embed Console as Console
	embed StringUtils as StringUtils
	embed Runtime as Runtime
	embed File as File
	embed Math as Math

	inputPort InspectionUtils {
		location: "local://InspectionUtils"
		interfaces: InspectionUtilsInterface
	}

	outputPort LanguageClient {
		location: "local://Client"
		interfaces: ServerToClient
	}

	init {
		println@Console("InspectionUtils Service started at "+ global.inputPorts.InspectionUtils.location + ".")()//" connected to " + LanguageClient.location )()
	}

	define createInspectionReq {
		// TODO : fix these:
		// - remove the directories of this LSP
		// - add the directory of the open file.
		getenv@Runtime( "JOLIE_HOME" )( jHome )
		getFileSeparator@File()( fs )
		getParentPath@File( request.uri )( documentPath )
		regexRequest << request.uri
		regexRequest.regex =  "^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?"
		find@StringUtils( regexRequest )( regexResponse )
		inspectionReq << {
			filename = regexResponse.group[5]
			source = request.text
			includePaths[0] = jHome + fs + "include"
			includePaths[1] = documentPath
		}
		replacementRequest = regexResponse.group[5]
		replacementRequest.regex = "%20"
		replacementRequest.replacement = " "
		replaceAll@StringUtils(replacementRequest)(inspectionReq.filename)

		replacementRequest = inspectionReq.includePaths[1]
		replaceAll@StringUtils(replacementRequest)(inspectionReq.includePaths[1])
	}

	define callInspection {
		scope(inspection){
			install( CodeCheckException =>
				println@Console("CodeCheckException!")()
				stderr << inspection.CodeCheckException

				//valueToPrettyString@StringUtils(codeMessage)(pretty)
				//println@Console("CodeCheckExceptionres:\n"+pretty)()
				//valueToPrettyString@StringUtils(inspection.CodeCheckException)(pretty)
				//println@Console("inspection.CodeCheckExceptionres:\n"+pretty)()
				for(codeMessage in stderr.exceptions){
					if(is_defined(codeMessage.context)){
						startLine << codeMessage.context.startLine
						endLine << codeMessage.context.endLine
						startColumn << codeMessage.context.startColumn
						endColumn << codeMessage.context.endColumn
					} else {
						startLine = 1
						endLine = 1
						startColumn = 0
						endColumn = 0
					}
					if(is_defined(codeMessage.description)){
						message = codeMessage.description
					} else {
						message = ""
					}
					if(is_defined(codeMessage.help)){
						message += codeMessage.help
					}
					//severity
					//TODO alwayes return error, never happend to get a warning
					//but this a problem of the jolie parser
					s = 1

					diagnosticParams << {
						uri << request.uri
						diagnostics << {
							severity = s
							range << {
								start << {
									line = startLine
									character = abs@Math(startColumn)
								}
								end << {
									line = endLine
									character = abs@Math(endColumn)
								}
							}
							source = "jolie"
							message = message
						}
					}
				}
			);
			install( FileNotFoundException =>
				temperr << inspection.FileNotFoundException
				println@Console("Error during file inspection:\n"+temperr.stackTrace)()
				diagnosticParams << {
					uri = "file:" + documentUri
					diagnostics = void
				}
			);
			install(IOException =>
				temperr << inspection.IOException
				println@Console("Error during file inspection:\n"+temperr.stackTrace)()
				diagnosticParams << {
					uri = "file:" + documentUri
					diagnostics = void
				}
			);
			install(default =>
				println@Console("Error happened while inspecting file!")()
				temperr = inspection.(inspection.default)
				temperr.regex =  "\\s*(.+):\\s*(\\d+):\\s*(error|warning)\\s*:\\s*(.+)"
				find@StringUtils( temperr )( matchRes )
				if(matchRes != 0){ // if matchRes is not 0, then it found a match for the regex, and we try to create a diagnostic
					// getting the uri of the document to be checked
					// have to do this because the inspector, when returning an error,
					// returns an uri that looks the following:
					// /home/eferos93/.atom/packages/Jolie-ide-atom/server/file:/home/eferos93/.atom/packages/Jolie-ide-atom/server/utils.ol
					// same was with jolie --check
					if ( !(matchRes.group[1] instanceof string) ) {
						matchRes.group[1] = ""
					}
					indexOf@StringUtils( matchRes.group[1] {
						word = "file:"
					} )( indexOfRes )
					if ( indexOfRes > -1 ) {
						subStrReq = matchRes.group[1]
						subStrReq.begin = indexOfRes + 5
						substring@StringUtils( subStrReq )( documentUri ) //line
					} else {
						replaceRequest = matchRes.group[1]
						replaceRequest.regex = "\\\\";
						replaceRequest.replacement = "/"
						replaceAll@StringUtils( replaceRequest )( documentUri )// documentUri = "///" + fileName
					}

					//line
					l = int( matchRes.group[2] )
					//severity
					sev -> matchRes.group[3]
					//TODO alwayes return error, never happend to get a warning
					//but this a problem of the jolie parser
					if ( sev == "error" ) {
						s = 1
					} else {
						s = 1
					}

					diagnosticParams << {
						uri = "file:" + documentUri
						diagnostics << {
						range << {
							start << {
								line = l
								character = 1
							}
							end << {
								line = l
								character = INTEGER_MAX_VALUE
							}
						}
						severity = s
						source = "jolie"
						message = matchRes.group[4]
						}
					}
				} else { // if the matchRes == 0, then the error did not have the expected format, and the normal diagnostics cannot be made
					println@Console("Stacktrace of unknown error:\n"+inspection.(inspection.default).stackTrace)()
					diagnosticParams << {
						uri = "file:" + documentUri
						diagnostics = void
					}
				}

			)
			// call local procedure to create inspection request
			createInspectionReq

			inspectFile@Inspector( inspectionReq )( inspectionRes )
			println@Console("No error happened while running inspectFile")()
			valueToPrettyString@StringUtils(inspectionRes)(pretty)
			println@Console("inspectionres:\n"+pretty)()
			// no error happened, so we make an empty diagnostic to publish
			diagnosticParams << {
				uri << request.uri
				diagnostics = void
			}
		}
	}

	main{
		/*
		* This call is to check wether the source code contains errors,
		* and it publishes the errors inspectFile found
		*/
		[inspectDocument(request)(inspectionRes) {
			println@Console("Inside inspectDocument")()
			callInspection
			publishDiagnostics@LanguageClient( diagnosticParams )
		}]

		/*
		* This call is used for returning the found error diagnostics instead of publishing them.
		* Is used by codeLens (which is not used).
		*/
		[inspectDocumentReturnDiagnostics(request)(diagnosticParams){
			println@Console("inside inspectDocumentReturnDiagnostics")()
			callInspection
		}]

		/*
		* This call is used by services which require the inspection request to inspect a file
		* or to find symbols by inspecting the file
		*/
		[createMinimalInspectionRequest(request)(inspectionReq){
			// call local procedure to create request
			createInspectionReq
		}]
	}
}
