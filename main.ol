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
from string_utils import StringUtils
from console import Console
from runtime import Runtime
from .internal.text-document import TextDocument
from .internal.workspace import Workspace
from .internal.utils import Utils
from .internal.inspection-utils import InspectionUtils
from .internal.completionHelper import CompletionHelper
from .lsp import GeneralInterface, ServerToClient, GlobalVariables

type Params {
	location: string
	debug?: bool
}

/**
 * Main Service that communicates directly with the client and provides the basic
 * operations.
 */
service Main(params:Params) {
	execution: sequential

	embed Console as Console
	embed Utils
	embed TextDocument as TextDocument
	embed Workspace as Workspace
	embed InspectionUtils
	embed CompletionHelper
	embed StringUtils as StringUtils

	inputPort Input {
		location: params.location
		protocol: jsonrpc { //.debug = true
			clientLocation -> global.clientLocation
			clientOutputPort = "Client"
			transport = "lsp"
			osc.onExit.alias = "exit"
			osc.cancelRequest.alias = "$/cancelRequest"
			osc.setTrace.alias = "$/setTrace"
			osc.didOpen.alias = "textDocument/didOpen"
			osc.didChange.alias = "textDocument/didChange"
			osc.willSave.alias = "textDocument/willSave"
			osc.didSave.alias = "textDocument/didSave"
			osc.didClose.alias = "textDocument/didClose"
			osc.completion.alias = "textDocument/completion"
			osc.hover.alias = "textDocument/hover"
			osc.documentSymbol.alias = "textDocument/documentSymbol"
			osc.publishDiagnostics.alias = "textDocument/publishDiagnostics"
			osc.publishDiagnostics.isNullable = true
			osc.signatureHelp.alias = "textDocument/signatureHelp"
			osc.definition.alias = "textDocument/definition"
			osc.rename.alias = "textDocument/rename"
			osc.didChangeWatchedFiles.alias = "workspace/didChangeWatchedFiles"
			osc.didChangeWorkspaceFolders.alias = "workspace/didChangeWorkspaceFolders"
			osc.didChangeConfiguration.alias = "workspace/didChangeConfiguration"
			osc.symbol.alias = "workspace/symbol"
			osc.executeCommand.alias = "workspace/executeCommand"
		}
		interfaces: GeneralInterface
		aggregates: TextDocument, Workspace
	}

	// Extra port for textdocument and workspace to get the root uri for when working on all files in the workspace
	inputPort GlobalVar {
		location: "local://GlobalVar"
		interfaces: GlobalVariables
	}


	/*
	* port that points to the client, used for publishing diagnostics
	*/
	outputPort Client {
		protocol: jsonrpc {
			transport = "lsp"
			debug = Debug
			debug.showContent = Debug
		}
		interfaces: ServerToClient
	}

	/*
	* port in which we receive the messages to be forwarded to the client
	*/
	inputPort NotificationsToClient {
		location: "local://Client"
		interfaces: ServerToClient
	}
	
	init {
		Client.location -> global.clientLocation
		if( is_defined( params.debug ) ) {
			global.inputPorts.Input.protocol.debug = params.debug
			global.inputPorts.Input.protocol.debug.showContent = params.debug
		}
		println@Console( "Jolie Language Server started" )()
		global.receivedShutdownReq = false
		//we want full document sync as we build the ProgramInspector for each
		//time we modify the document
	}

	main {
		[ initialize( initializeParams )( serverCapabilities ) {
			println@Console( "Initialize message received" )()
			global.processId = initializeParams.processId
			global.rootUri = initializeParams.rootUri
			global.clientCapabilities << initializeParams.capabilities
			global.trace = initializeParams.trace
			//for full serverCapabilities spec, see
			// https://microsoft.github.io/language-server-protocol/specification
			// and types.iol
			serverCapabilities.capabilities << {
				textDocumentSync = 1 //0 = none, 1 = full, 2 = incremental
				completionProvider << {
					resolveProvider = false
					triggerCharacters[0] = "@"
				}
				//signatureHelpProvider.triggerCharacters[0] = "("
				definitionProvider = true
				hoverProvider = true
				declarationProvider = false
				documentSymbolProvider = false
				referencesProvider = false
				//experimental;
				workspaceSymbolProvider = true
				renameProvider = true
			}
		}]

		[ initialized( initializedParams ) ] {
			println@Console( "Initialization done " )()
		}

		[ shutdown( req )( res ) {
			println@Console( "Shutdown request received..." )()
			global.receivedShutdownReq = true
		}]

		[ onExit( notification ) ] {
			if( !global.receivedShutdownReq ) {
				println@Console( "Did not receive the shutdown request, exiting anyway..." )()
			}
			println@Console( "Exiting Jolie Language server..." )()
			exit
		}
		
		//received from syntax_checker.ol
		[ publishDiagnostics( diagnosticParams ) ] {
			println@Console( "publishing diagnostics for " + diagnosticParams.uri )()
			publishDiagnostics@Client( diagnosticParams )
		}

		[ cancelRequest( cancelReq ) ] {
			println@Console( "cancelRequest received ID: " + cancelReq.id )()
			//TODO
		}

		[ setTrace( setTraceReq ) ] {
			println@Console( "setTrace received value: " + setTraceReq.value )()
			global.trace = setTraceReq.value
		}

		// helper to get root uri of the workspace for workspace/symbol and textdocument/rename
		// as this is not provided from the request to these functionalities
		[getRootUri(request)(response){
			response = global.rootUri
		}]
	}
}
