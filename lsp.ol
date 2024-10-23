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
/*
 * Jolie types for the Language Server Protocol
 * see https://microsoft.github.io/language-server-protocol/specification
 */

/*
 * @author Eros Fabrici
 */

type InitializeParams {
	processId: int | void

	/**
	 * Information about the client
	 *
	 * @since 3.15.0
	 */
	clientInfo? {
		/**
		 * The name of the client as defined by the client.
		 */
		name: string

		/**
		 * The client's version as defined by the client.
		 */
		version?: string
	}

	/**
	 * The locale the client is currently showing the user interface
	 * in. This must not necessarily be the locale of the operating
	 * system.
	 *
	 * Uses IETF language tags as the value's syntax
	 * (See https://en.wikipedia.org/wiki/IETF_language_tag)
	 *
	 * @since 3.16.0
	 */
	locale?: string

	rootPath?: string | void
	rootUri: DocumentUri | void
	initializationOptions?: undefined
	capabilities: ClientCapabilities
	trace?: string // "off" | "messages" | "verbose"
	workspaceFolders*: WorkspaceFolder | void
}

type WorkspaceFolder {
	uri: string
	name: string
}

type DocumentUri: string


type TextDocumentIdentifier {
	uri: DocumentUri
}

type VersionedTextDocumentIdentifier {
	uri: DocumentUri
	version: int | void
}

type NotebookDocumentSyncClientCapabilities {
	/**
	 * Whether implementation supports dynamic registration. If this is
	 * set to `true` the client supports the new
	 * `(NotebookDocumentSyncRegistrationOptions & NotebookDocumentSyncOptions)`
	 * return value for the corresponding server capability as well.
	 */
	dynamicRegistration?: bool

	/**
	 * The client supports sending execution summary data per cell.
	 */
	executionSummarySupport?: bool
}

type ClientCapabilities {
	workspace?: WorkspaceClientCapabilities
	textDocument?: TextDocumentClientCapabilities
	
	/**
	 * Capabilities specific to the notebook document support.
	 *
	 * @since 3.17.0
	 */
	notebookDocument? {
		/**
		* Capabilities specific to notebook document synchronization
		*
		* @since 3.17.0
		*/
		synchronization: NotebookDocumentSyncClientCapabilities
	}

	/**
	 * Window specific client capabilities.
	 */
	window? {
		/**
		 * It indicates whether the client supports server initiated
		 * progress using the `window/workDoneProgress/create` request.
		 *
		 * The capability also controls Whether client supports handling
		 * of progress notifications. If set servers are allowed to report a
		 * `workDoneProgress` property in the request specific server
		 * capabilities.
		 *
		 * @since 3.15.0
		 */
		workDoneProgress?: bool

		/**
		 * Capabilities specific to the showMessage request
		 *
		 * @since 3.16.0
		 */
		showMessage? {
			/**
			* Capabilities specific to the `MessageActionItem` type.
			*/
			messageActionItem? {
				/**
				* Whether the client supports additional attributes which
				* are preserved and sent back to the server in the
				* request's response.
				*/
				additionalPropertiesSupport?: bool
			}
		}

		/**
		 * Client capabilities for the show document request.
		 *
		 * @since 3.16.0
		 */
		showDocument? {
			/**
			* The client has support for the show document
			* request.
			*/
			support: bool
		}
	}

	/**
	 * General client capabilities.
	 *
	 * @since 3.16.0
	 */
	general? {
		/**
		 * Client capability that signals how the client
		 * handles stale requests (e.g. a request
		 * for which the client will not process the response
		 * anymore since the information is outdated).
		 *
		 * @since 3.17.0
		 */
		staleRequestSupport? {
			/**
			 * The client will actively cancel the request.
			 */
			cancel: bool

			/**
			 * The list of requests for which the client
			 * will retry the request if it receives a
			 * response with error code `ContentModified``
			 */
			 retryOnContentModified*: string
		}

		/**
		 * Client capabilities specific to regular expressions.
		 *
		 * @since 3.16.0
		 */
		regularExpressions? {
			/**
			* The engine's name.
			*/
			engine: string

			/**
			* The engine's version.
			*/
			version?: string
		}

		/**
		 * Client capabilities specific to the client's markdown parser.
		 *
		 * @since 3.16.0
		 */
		markdown? {
			/**
			* The name of the parser.
			*/
			parser: string

			/**
			* The version of the parser.
			*/
			version?: string

			/**
			* A list of HTML tags that the client allows / supports in
			* Markdown.
			*
			* @since 3.17.0
			*/
			allowedTags*: string
		}

		/**
		 * The position encodings supported by the client. Client and server
		 * have to agree on the same position encoding to ensure that offsets
		 * (e.g. character position in a line) are interpreted the same on both
		 * side.
		 * @since 3.17.0
		 */
		positionEncodings?: string
	}

	experimental?: undefined
}

type WorkspaceClientCapabilities {
	foldingRange?: undefined
	applyEdit?: bool
	workspaceEdit? {
		documentChanges?: bool
		resourceOperations*: ResourceOperationKind
		failureHandling?: FailureHandlingKind
		normalizesLineEndings?: bool
		changeAnnotationSupport? {
			/**
			* Whether the client groups edits with equal labels into tree nodes,
			* for instance all edits labelled with "Changes in Strings" would
			* be a tree node.
			*/
			groupsOnLabel?: bool
		}
	}
	didChangeConfiguration? {
		dynamicRegistration?: bool
	}
	didChangeWatchedFiles? {
		dynamicRegistration?: bool
		relativePatternSupport?: bool
	}
	symbol? {
		dynamicRegistration?: bool
		symbolKind? {
			valueSet*: SymbolKind
		}
		tagSupport? {
			valueSet*: SymbolTag
		}
		/**
		* The client supports partial workspace symbols. The client will send the
		* request `workspaceSymbol/resolve` to the server to resolve additional
		* properties.
		*
		* @since 3.17.0 - proposedState
		*/
		resolveSupport? {
			properties*: string
		}
	}
	executeCommand? {
		dynamicRegistration?: bool
	}
	workspaceFolders?: bool
	configuration?: bool

	/**
		* Capabilities specific to the semantic token requests scoped to the
		* workspace.
		*
		* @since 3.16.0
		*/
		semanticTokens?  {
			/**
			* Whether the client implementation supports a refresh request sent from
			* the server to the client.
			*
			* Note that this event is global and will force the client to refresh all
			* semantic tokens currently shown. It should be used with absolute care
			* and is useful for situation where a server for example detect a project
			* wide change that requires such a calculation.
			*/
			refreshSupport?: bool
		}

	/**
		* Capabilities specific to the code lens requests scoped to the
		* workspace.
		*
		* @since 3.16.0
		*/
	codeLens? {
		/**
		* Whether the client implementation supports a refresh request sent from the
		* server to the client.
		*
		* Note that this event is global and will force the client to refresh all
		* code lenses currently shown. It should be used with absolute care and is
		* useful for situation where a server for example detect a project wide
		* change that requires such a calculation.
		*/
		refreshSupport?: bool
	}

	/**
		* The client has support for file requests/notifications.
		*
		* @since 3.16.0
		*/
	fileOperations? {
		/**
			* Whether the client supports dynamic registration for file
			* requests/notifications.
			*/
		dynamicRegistration?: bool

		/**
			* The client has support for sending didCreateFiles notifications.
			*/
		didCreate?: bool

		/**
			* The client has support for sending willCreateFiles requests.
			*/
		willCreate?: bool

		/**
			* The client has support for sending didRenameFiles notifications.
			*/
		didRename?: bool

		/**
			* The client has support for sending willRenameFiles requests.
			*/
		willRename?: bool

		/**
			* The client has support for sending didDeleteFiles notifications.
			*/
		didDelete?: bool

		/**
			* The client has support for sending willDeleteFiles requests.
			*/
		willDelete?: bool
	}

	/**
		* Client workspace capabilities specific to inline values.
		*
		* @since 3.17.0
		*/
	inlineValue? {
		/**
		* Whether the client implementation supports a refresh request sent from
		* the server to the client.
		*
		* Note that this event is global and will force the client to refresh all
		* inline values currently shown. It should be used with absolute care and
		* is useful for situation where a server for example detect a project wide
		* change that requires such a calculation.
		*/
		refreshSupport?: bool
	}

	/**
	* Client workspace capabilities specific to inlay hints.
	*
	* @since 3.17.0
	*/
	inlayHint?  {
		/**
		* Whether the client implementation supports a refresh request sent from
		* the server to the client.
		*
		* Note that this event is global and will force the client to refresh all
		* inlay hints currently shown. It should be used with absolute care and
		* is useful for situation where a server for example detects a project wide
		* change that requires such a calculation.
		*/
		refreshSupport?: bool
	}

	/**
		* Client workspace capabilities specific to diagnostics.
		*
		* @since 3.17.0.
		*/
	diagnostics?  {
		/**
		* Whether the client implementation supports a refresh request sent from
		* the server to the client.
		*
		* Note that this event is global and will force the client to refresh all
		* pulled diagnostics currently shown. It should be used with absolute care
		* and is useful for situation where a server for example detects a project
		* wide change that requires such a calculation.
		*/
		refreshSupport?: bool
	}
}

type ResourceOperationKind: string //namespace, see official spec
type FailureHandlingKind: string //namespace, see official spec
type MarkupKind: string //namespace, see official spec
type SymbolKind: int //namespace, see official spec
type SymbolTag: int //namespace, see official spec
type CompletionItemKind: int // namespace, see official spec
type CodeActionKind: string //namespace, see official spec

type TextDocumentClientCapabilities {
	synchronization? {
		dynamicRegistration?: bool
		willSave?: bool
		willSaveWaitUntil?: bool
		didSave?: bool
	}
	completion? {
		dynamicRegistration?: bool
		completionItem? {
			snippetSupport?: bool
			commitCharactersSupport?: bool
			documentationFormat*: MarkupKind
			deprecatedSupport?: bool
			preselectSupport?: bool

			/**
			* Client supports the tag property on a completion item. Clients
			* supporting tags have to handle unknown tags gracefully. Clients
			* especially need to preserve unknown tags when sending a completion
			* item back to the server in a resolve call.
			*
			* @since 3.15.0
			*/
			tagSupport? {
				/**
				* The tags supported by the client.
				*/
				valueSet*: int
			}

			/**
			* Client supports insert replace edit to control different behavior if
			* a completion item is inserted in the text or should replace text.
			*
			* @since 3.16.0
			*/
			insertReplaceSupport?: bool

			/**
			* Indicates which properties a client can resolve lazily on a
			* completion item. Before version 3.16.0 only the predefined properties
			* `documentation` and `detail` could be resolved lazily.
			*
			* @since 3.16.0
			*/
			resolveSupport? {
				/**
				* The properties that a client can resolve lazily.
				*/
				properties*: string
			}

			/**
			* The client supports the `insertTextMode` property on
			* a completion item to override the whitespace handling mode
			* as defined by the client (see `insertTextMode`).
			*
			* @since 3.16.0
			*/
			insertTextModeSupport? {
				valueSet*: int
			}

			/**
			* The client has support for completion item label
			* details (see also `CompletionItemLabelDetails`).
			*
			* @since 3.17.0
			*/
			labelDetailsSupport?: bool
		}
		completionItemKind? {
			valueSet*: CompletionItemKind
		}
		contextSupport?: bool

		/**
		* The client's default when the completion item doesn't provide a
		* `insertTextMode` property.
		*
		* @since 3.17.0
		*/
		insertTextMode?: int

		/**
		* The client supports the following `CompletionList` specific
		* capabilities.
		*
		* @since 3.17.0
		*/
		completionList? {
			/**
			* The client supports the following itemDefaults on
			* a completion list.
			*
			* The value lists the supported property names of the
			* `CompletionList.itemDefaults` object. If omitted
			* no properties are supported.
			*
			* @since 3.17.0
			*/
			itemDefaults*: string
		}
	}
	hover? {
		dynamicRegistration?: bool
		contentFormat*: MarkupKind
	}
	signatureHelp? {
		dynamicRegistration?: bool
		signatureInformation? {
			documentationFormat*: MarkupKind
			parameterInformation? {
				labelOffsetSupport?: bool
			}
			/**
			* The client supports the `activeParameter` property on
			* `SignatureInformation` literal.
			*
			* @since 3.16.0
			*/
			activeParameterSupport?: bool
		}


		/**
		* The client supports to send additional context information for a
		* `textDocument/signatureHelp` request. A client that opts into
		* contextSupport will also support the `retriggerCharacters` on
		* `SignatureHelpOptions`.
		*
		* @since 3.15.0
		*/
		contextSupport?: bool
	}
	references? {
		dynamicRegistration?: bool
	}
	documentHighlight? {
		dynamicRegistration?: bool
	}
	documentSymbol? {
		dynamicRegistration?: bool
		symbolKind? {
			valueSet*: SymbolKind
		}
		hierarchicalDocumentSymbolSupport?: bool
		/**
		* The client supports tags on `SymbolInformation`. Tags are supported on
		* `DocumentSymbol` if `hierarchicalDocumentSymbolSupport` is set to true.
		* Clients supporting tags have to handle unknown tags gracefully.
		*
		* @since 3.16.0
		*/
		tagSupport? {
			/**
			* The tags supported by the client.
			*/
			valueSet*: int
		}

		/**
		* The client supports an additional label presented in the UI when
		* registering a document symbol provider.
		*
		* @since 3.16.0
		*/
		labelSupport?: bool
	}
	formatting? {
		dynamicRegistration?: bool
	}
	rangeFormatting? {
		dynamicRegistration?: bool
		rangeSupport?: undefined
	}
	onTypeFormatting? {
		dynamicRegistration?: bool
	}
	declaration? {
		dynamicRegistration?: bool
		linkSupport?: bool
	}
	definition? {
		dynamicRegistration?: bool
		linkSupport?: bool
	}
	typeDefinition? {
		dynamicRegistration?: bool
		linkSupport?: bool
	}
	implementation? {
		dynamicRegistration?: bool
		linkSupport?: bool
	}
	codeAction? {
		dynamicRegistration?: bool
		codeActionLiteralSupport? {
			codeActionKind {
				valueSet[1,*]: CodeActionKind
			}
		}

		/**
		* Whether code action supports the `isPreferred` property.
		*
		* @since 3.15.0
		*/
		isPreferredSupport?: bool

		/**
		* Whether code action supports the `disabled` property.
		*
		* @since 3.16.0
		*/
		disabledSupport?: bool

		/**
		* Whether code action supports the `data` property which is
		* preserved between a `textDocument/codeAction` and a
		* `codeAction/resolve` request.
		*
		* @since 3.16.0
		*/
		dataSupport?: bool


		/**
		* Whether the client supports resolving additional code action
		* properties via a separate `codeAction/resolve` request.
		*
		* @since 3.16.0
		*/
		resolveSupport? {
			/**
			* The properties that a client can resolve lazily.
			*/
			properties*: string
		}

		/**
		* Whether the client honors the change annotations in
		* text edits and resource operations returned via the
		* `CodeAction#edit` property by for example presenting
		* the workspace edit in the user interface and asking
		* for confirmation.
		*
		* @since 3.16.0
		*/
		honorsChangeAnnotations?: bool
		
	}
	codeLens? {
		dynamicRegistration?: bool
	}
	documentLink? {
		dynamicRegistration?: bool

		/**
		* Whether the client supports the `tooltip` property on `DocumentLink`.
		*
		* @since 3.15.0
		*/
		tooltipSupport?: bool
	}
	rename? {
		dynamicRegistration?: bool
		prepareSupport?: bool
		/**
		* Client supports the default behavior result
		* (`{ defaultBehavior: boolean }`).
		*
		* The value indicates the default behavior used by the
		* client.
		*
		* @since version 3.16.0
		*/
		prepareSupportDefaultBehavior?: int

		/**
		* Whether the client honors the change annotations in
		* text edits and resource operations returned via the
		* rename request's workspace edit by for example presenting
		* the workspace edit in the user interface and asking
		* for confirmation.
		*
		* @since 3.16.0
		*/
		honorsChangeAnnotations?: bool

	}
	publishDiagnostics? {
		relatedInformation?: bool

		/**
		* Client supports the tag property to provide meta data about a diagnostic.
		* Clients supporting tags have to handle unknown tags gracefully.
		*
		* @since 3.15.0
		*/
		tagSupport? {
			/**
			* The tags supported by the client.
			*/
			valueSet*: int
		}

		/**
		* Whether the client interprets the version property of the
		* `textDocument/publishDiagnostics` notification's parameter.
		*
		* @since 3.15.0
		*/
		versionSupport?: bool

		/**
		* Client supports a codeDescription property
		*
		* @since 3.16.0
		*/
		codeDescriptionSupport?: bool

		/**
		* Whether code action supports the `data` property which is
		* preserved between a `textDocument/publishDiagnostics` and
		* `textDocument/codeAction` request.
		*
		* @since 3.16.0
		*/
		dataSupport?: bool
	}

	/**
	 * Capabilities specific to the `textDocument/foldingRange` request.
	 *
	 * @since 3.10.0
	 */
	foldingRange? {
		dynamicRegistration?: bool
		rangeLimit?: int
		lineFoldingOnly?: bool

		/**
		* Specific options for the folding range kind.
		*
		* @since 3.17.0
		*/
		foldingRangeKind? {
			/**
			* The folding range kind values the client supports. When this
			* property exists the client also guarantees that it will
			* handle values outside its set gracefully and falls back
			* to a default value when unknown.
			*/
			valueSet*: string
		}

		/**
		* Specific options for the folding range.
		* @since 3.17.0
		*/
		foldingRange? {
			/**
			* If set, the client signals that it supports setting collapsedText on
			* folding ranges to display custom labels instead of the default text.
			*
			* @since 3.17.0
			*/
			collapsedText?: bool
		}
	}

	/**
	 * Capabilities specific to the `textDocument/selectionRange` request.
	 *
	 * @since 3.15.0
	 */
	selectionRange? {
		/**
		* Whether implementation supports dynamic registration for selection range
		* providers. If this is set to `true` the client supports the new
		* `SelectionRangeRegistrationOptions` return value for the corresponding
		* server capability as well.
		*/
		dynamicRegistration?: bool
	}

	/**
	 * Capabilities specific to the `textDocument/linkedEditingRange` request.
	 *
	 * @since 3.16.0
	 */
	linkedEditingRange?  {
		/**
		* Whether the implementation supports dynamic registration.
		* If this is set to `true` the client supports the new
		* `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
		* return value for the corresponding server capability as well.
		*/
		dynamicRegistration?: bool
	}

	/**
	 * Capabilities specific to the various call hierarchy requests.
	 *
	 * @since 3.16.0
	 */
	callHierarchy?  {
		/**
		* Whether implementation supports dynamic registration. If this is set to
		* `true` the client supports the new `(TextDocumentRegistrationOptions &
		* StaticRegistrationOptions)` return value for the corresponding server
		* capability as well.
		*/
		dynamicRegistration?: bool
	}

	/**
	 * Capabilities specific to the various semantic token requests.
	 *
	 * @since 3.16.0
	 */
	semanticTokens? {
		/**
		* Whether implementation supports dynamic registration. If this is set to
		* `true` the client supports the new `(TextDocumentRegistrationOptions &
		* StaticRegistrationOptions)` return value for the corresponding server
		* capability as well.
		*/
		dynamicRegistration?: bool
		/**
		* Which requests the client supports and might send to the server
		* depending on the server's capability. Please note that clients might not
		* show semantic tokens or degrade some of the user experience if a range
		* or full request is advertised by the client but not provided by the
		* server. If for example the client capability `requests.full` and
		* `request.range` are both set to true but the server only provides a
		* range provider the client might not render a minimap correctly or might
		* even decide to not show any semantic tokens at all.
		*/
		requests {
			/**
			* The client will send the `textDocument/semanticTokens/range` request
			* if the server provides a corresponding handler.
			*/
			range?: bool | void

			/**
			* The client will send the `textDocument/semanticTokens/full` request
			* if the server provides a corresponding handler.
			*/
			full?: undefined
		}

		/**
		* The token types that the client supports.
		*/
		tokenTypes*: string

		/**
		* The token modifiers that the client supports.
		*/
		tokenModifiers*: string

		/**
		* The formats the clients supports.
		*/
		formats: string

		/**
		* Whether the client supports tokens that can overlap each other.
		*/
		overlappingTokenSupport?: bool

		/**
		* Whether the client supports tokens that can span multiple lines.
		*/
		multilineTokenSupport?: bool

		/**
		* Whether the client allows the server to actively cancel a
		* semantic token request, e.g. supports returning
		* ErrorCodes.ServerCancelled. If a server does the client
		* needs to retrigger the request.
		*
		* @since 3.17.0
		*/
		serverCancelSupport?: bool

		/**
		* Whether the client uses semantic tokens to augment existing
		* syntax tokens. If set to `true` client side created syntax
		* tokens and semantic tokens are both used for colorization. If
		* set to `false` the client only uses the returned semantic tokens
		* for colorization.
		*
		* If the value is `undefined` then the client behavior is not
		* specified.
		*
		* @since 3.17.0
		*/
		augmentsSyntaxTokens?: bool
	}

	/**
	 * Capabilities specific to the `textDocument/moniker` request.
	 *
	 * @since 3.16.0
	 */
	moniker? {
		/**
		* Whether implementation supports dynamic registration. If this is set to
		* `true` the client supports the new `(TextDocumentRegistrationOptions &
		* StaticRegistrationOptions)` return value for the corresponding server
		* capability as well.
		*/
		dynamicRegistration?: bool
	}

	/**
	 * Capabilities specific to the various type hierarchy requests.
	 *
	 * @since 3.17.0
	 */
	typeHierarchy? {
		/**
		* Whether implementation supports dynamic registration. If this is set to
		* `true` the client supports the new `(TextDocumentRegistrationOptions &
		* StaticRegistrationOptions)` return value for the corresponding server
		* capability as well.
		*/
		dynamicRegistration?: bool
	}

	/**
	 * Capabilities specific to the `textDocument/inlineValue` request.
	 *
	 * @since 3.17.0
	 */
	inlineValue? {
		/**
		* Whether implementation supports dynamic registration for inline
		* value providers.
		*/
		dynamicRegistration?: bool
	}

	/**
	 * Capabilities specific to the `textDocument/inlayHint` request.
	 *
	 * @since 3.17.0
	 */
	inlayHint? {

		/**
		* Whether inlay hints support dynamic registration.
		*/
		dynamicRegistration?: bool

		/**
		* Indicates which properties a client can resolve lazily on an inlay
		* hint.
		*/
		resolveSupport? {

			/**
			* The properties that a client can resolve lazily.
			*/
			properties*: string
					}
				}

	/**
	 * Capabilities specific to the diagnostic pull model.
	 *
	 * @since 3.17.0
	 */
	diagnostic? {
		/**
		* Whether implementation supports dynamic registration. If this is set to
		* `true` the client supports the new
		* `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
		* return value for the corresponding server capability as well.
		*/
		dynamicRegistration?: bool

		/**
		* Whether the clients supports related documents for document diagnostic
		* pulls.
		*/
		relatedDocumentSupport?: bool
			}

	colorProvider? {
		dynamicRegistration?: bool
	}
}

type InitializedParams: void

type InitializeResult {
	capabilities: ServerCapabilities

	/**
	 * Information about the server.
	 *
	 * @since 3.15.0
	 */
	serverInfo? {
		/**
		 * The name of the server as defined by the server.
		 */
		name: string

		/**
		 * The server's version as defined by the server.
		 */
		version?: string
	}
}

type FileOperationRegistrationOptions {
	/**
	 * The actual filters.
	 */
	filters* {
		/**
		* A Uri like `file` or `untitled`.
		*/
		scheme?: string

		/**
		* The actual file operation pattern.
		*/
		pattern {

			/**
			* The glob pattern to match. Glob patterns can have the following syntax:
			* - `*` to match one or more characters in a path segment
			* - `?` to match on one character in a path segment
			* - `**` to match any number of path segments, including none
			* - `{}` to group sub patterns into an OR expression. (e.g. `**​/*.{ts,js}`
			*   matches all TypeScript and JavaScript files)
			* - `[]` to declare a range of characters to match in a path segment
			*   (e.g., `example.[0-9]` to match on `example.0`, `example.1`, …)
			* - `[!...]` to negate a range of characters to match in a path segment
			*   (e.g., `example.[!0-9]` to match on `example.a`, `example.b`, but
			*   not `example.0`)
			*/
			glob: string

			/**
			* Whether to match files or folders with this pattern.
			*
			* Matches both if undefined.
			*/
			matches?: string

			/**
			* Additional options used during matching.
			*/
			options? {
				ignoreCase?: bool
			}
		}
	}
}

type ServerCapabilities {
	textDocumentSync?: TextDocumentSyncOptions | int
	hoverProvider?: bool
	completionProvider?: CompletionOptions
	signatureHelpProvider?: SignatureHelpOptions
	/**
	 * The server provides go to declaration support.
	 *
	 * @since 3.14.0
	 */
	declarationProvider?: bool //TODO see LSP specification
	definitionProvider?: bool
	typeDefinitionProvider?: undefined //TODO see LSP specification
	implementationProvider?: undefined //TODO see LSP specification
	referencesProvider?: undefined //TODO see LSP specification
	documentHighlightProvider?: bool
	documentSymbolProvider?: bool
	codeActionProvider?: bool
	codeLensProvider?: CodeLensOptions
	documentFormattingProvider?: bool
	documentRangeFormattingProvider?: bool
	documentOnTypeFormattingProvider?: DocumentOnTypeFormattingOptions
	renameProvider?: bool | RenameOptions
	documentLinkProvider?: DocumentLinkOptions
	colorProvider?: undefined //TODO see LSP specification
	foldingRangeProvider?: undefined //TODO see LSP specification
	executeCommandProvider?: ExecuteCommandOptions
	workspace? {
		foldingRange?: undefined
		workspaceFolders? {
			supported?: bool
			changeNotifications?: string | bool
		}

		/**
		* The server is interested in file notifications/requests.
		*
		* @since 3.16.0
		*/
		fileOperations? {
			/**
			* The server is interested in receiving didCreateFiles
			* notifications.
			*/
			didCreate?: FileOperationRegistrationOptions

			/**
			* The server is interested in receiving willCreateFiles requests.
			*/
			willCreate?: FileOperationRegistrationOptions

			/**
			* The server is interested in receiving didRenameFiles
			* notifications.
			*/
			didRename?: FileOperationRegistrationOptions

			/**
			* The server is interested in receiving willRenameFiles requests.
			*/
			willRename?: FileOperationRegistrationOptions

			/**
			* The server is interested in receiving didDeleteFiles file
			* notifications.
			*/
			didDelete?: FileOperationRegistrationOptions

			/**
			* The server is interested in receiving willDeleteFiles file
			* requests.
			*/
			willDelete?: FileOperationRegistrationOptions
		}
	}

	/**
	 * The server provides selection range support.
	 *
	 * @since 3.15.0
	 */
	selectionRangeProvider?: undefined //TODO see LSP specification

	/**
	 * The server provides linked editing range support.
	 *
	 * @since 3.16.0
	 */
	linkedEditingRangeProvider?: undefined //TODO see LSP specification

	/**
	 * The server provides call hierarchy support.
	 *
	 * @since 3.16.0
	 */
	callHierarchyProvider?: undefined //TODO see LSP specification

	/**
	 * The server provides semantic tokens support.
	 *
	 * @since 3.16.0
	 */
	semanticTokensProvider?: undefined //TODO see LSP specification

	/**
	 * Whether server provides moniker support.
	 *
	 * @since 3.16.0
	 */
	monikerProvider?: undefined //TODO see LSP specification

	/**
	 * The server provides type hierarchy support.
	 *
	 * @since 3.17.0
	 */
	typeHierarchyProvider?: undefined //TODO see LSP specification

	/**
	 * The server provides inline values.
	 *
	 * @since 3.17.0
	 */
	inlineValueProvider?: undefined //TODO see LSP specification

	/**
	 * The server provides inlay hints.
	 *
	 * @since 3.17.0
	 */
	inlayHintProvider?: undefined //TODO see LSP specification

	/**
	 * The server has support for pull model diagnostics.
	 *
	 * @since 3.17.0
	 */
	diagnosticProvider?: undefined //TODO see LSP specification

	workspaceSymbolProvider?: bool
	experimental?: undefined
}

type ExecuteCommandOptions {
	/*
	 * The commands to be executed on the server
	 */
	commands[1,*]: string
}

type DocumentLinkOptions {
	/*
	 * Document links have a resolve provider as well
	 */
	resolveProvider?: bool
}

type RenameOptions {
	/*
	 * Renames should be checked and tested before being executed
	 */
	prepareProvider?: bool
}

type DocumentOnTypeFormattingOptions {
	/*
	 * A character on which formatting should be triggered, like `}`
	 */
	firstTriggerCharacter: string
	/*
	 * More trigger characters
	 */
	moreTriggerCharacter*: string
}

type CodeLensOptions {
	/*
	 * Code lens has a resolve provider as well
	 */
	resolveProvider?: bool
}
type SignatureHelpOptions {
	/*
	 * The characters that trigger signature help
	 * automatically
	 */
	triggerCharacters*: string
	/**
	 * List of characters that re-trigger signature help.
	 *
	 * These trigger characters are only active when signature help is already
	 * showing. All trigger characters are also counted as re-trigger
	 * characters.
	 *
	 * @since 3.15.0
	 */
	retriggerCharacters*: string
}


type ParameterInformation {
	/*
	 * The label of this parameter information.
	 *
	 * Either a string or an inclusive start and exclusive end offsets within its containing
	 * signature label. (see SignatureInformation.label). The offsets are based on a UTF-16
	 * string representation as `Position` and `Range` does.
	 *
	 * *Note*: a label of type string should be a substring of its containing signature label.
	 * Its intended use case is to highlight the parameter label part in the `SignatureInformation.label`.
	 */
	label: string | void { _2: int } //string | [int, int]
	/*
	 * The human-readable doc-comment of this parameter. Will be shown
	 * in the UI but can be omitted.
	 */
	documentation?: string | MarkupContent
}

type SignatureInformation {
	label: string
	documentation?: string | MarkupContent
	parameters*: ParameterInformation

	/**
	 * The index of the active parameter.
	 *
	 * If provided, this is used in place of `SignatureHelp.activeParameter`.
	 *
	 * @since 3.16.0
	 */
	activeParameter?: int
	}

type SignatureHelp {
	signatures[1,*]: SignatureInformation
	/*
	 * The active signature. If omitted or the value lies outside the
	 * range of `signatures` the value defaults to zero or is ignored if
	 * `signatures.length === 0`. Whenever possible implementors should
	 * make an active decision about the active signature and shouldn't
	 * rely on a default value.
	 * In future version of the protocol this property might become
	 * mandatory to better express this.
	 */
	activeSignature?: int
	/*
	 * The active parameter of the active signature. If omitted or the value
	 * lies outside the range of `signatures[activeSignature].parameters`
	 * defaults to 0 if the active signature has parameters. If
	 * the active signature has no parameters it is ignored.
	 * In future version of the protocol this property might become
	 * mandatory to better express the active parameter if the
	 * active signature does have any.
	 */
	activeParameter?: int
}

type SignatureHelpResponse: SignatureHelp | void


type CompletionOptions {
	/*
	 * The server provides support to resolve additional
	 * information for a completion item
	 */
	resolveProvider?: bool
	/*
	 * The characters that trigger completion automatically
	 */
	triggerCharacters*: string
}

type TextDocumentSyncOptions {
	/*
	 * Open and close notifications are sent to the server If omitted open close notification should not
	 * be sent
	 */
	openClose?: bool
	/*
	 * Change notifications are sent to the server See TextDocumentSyncKindNone, TextDocumentSyncKindFull
	 * and TextDocumentSyncKindIncremental If omitted it defaults to TextDocumentSyncKindNone
	 */
	change?: int
	/*
	 * If present will save notifications are sent to the server If omitted the notification should not be
	 * sent
	 */
	willSave?: bool
	/*
	 * If present will save wait until requests are sent to the server If omitted the request should not be
	 * sent
	 */
	willSaveWaitUntil?: bool
	/*
	 * If present save notifications are sent to the server If omitted the notification should not be
	 * sent
	 */
	save?: SaveOptions
}

type SaveOptions {
	includeText?: bool
}

type DidOpenTextDocumentParams {
	textDocument: TextDocumentItem
}

type TextDocumentItem {
	/*
	 * The text document's URI
	 */
	uri: DocumentUri
	/*
	 * The text document's language identifier
	 */
	languageId: string
	/*
	 * The version number of this document (it will increase after each
	 * change, including undo/redo)
	 */
	version: int
	/*
	 * The content of the opened text document
	 */
	text: string
}

type DidChangeTextDocumentParams {
	/*
	 * The document that did change The version number points
	 * to the version after all provided content changes have
	 * been applied
	 */
	textDocument: VersionedTextDocumentIdentifier
	/*
	 * The actual content changes The content changes describe single state changes
	 * to the document So if there are two content changes c1 and c2 for a document
	 * in state S then c1 move the document to S' and c2 to S''
	 */
	contentChanges[1,*]: TextDocumentContentChangeEvent
}

type TextDocumentContentChangeEvent {
	/*
	 * The range of the document that changed
	 */
	range?: Range
	/*
	 * The length of the range that got replaced
	 */
	rangeLength?: int
	/*
	 * The new text of the range/document
	 */
	text: string
}

type Range {
	start: Position
	end: Position
}

type Position {
	/*
	 * Line position in a document (zero-based)
	 */
	line: int

	/*
	 * Character offset on a line in a document (zero-based) Assuming that the line is
	 * represented as a string, the `character` value represents the gap between the
	 * `character` and `character + 1`
	 *
	 * If the character value is greater than the line length it defaults back to the
	 * line length
	 */
	character: int
}

type WillSaveTextDocumentParams {
	textDocument: TextDocumentIdentifier
	reason: int // 1=Manual, 2=afterDelay, 3=FocusOut
}

type WillSaveWaitUntilResponse: TextEdit | void //TextEdit[1,*]

type DidSaveTextDocumentParams {
	textDocument: VersionedTextDocumentIdentifier
	text?: string
}

type DidCloseTextDocumentParams {
	textDocument: TextDocumentIdentifier
}

type TextEdit {
	range: Range
	newText: string
}

type TextDocumentPositionParams {
	textDocument: TextDocumentIdentifier
	position: Position
}

type CompletionParams {
	textDocument: TextDocumentIdentifier
	position: Position
	context?: CompletionContext
}

type CompletionContext {
	/*
	 * How the completion was triggered
	 * CompletionTriggerKind: 1 = Invoked, 2 = TriggerCharacter,
	 *                        3 = TriggerForIncompleteCompletions
	 */
	triggerKind: int

	/*
	 * The trigger character (a single character) that has trigger code complete
	 * Is undefined if `triggerKind !== CompletionTriggerKindTriggerCharacter`
	 */
	triggerCharacter?: string
}

type EmptyCompletionList {
	isIncomplete: bool
	items: void
}

type CompletionResult: CompletionList | EmptyCompletionList | void

type CompletionList {
	/*
	 * This list it not complete Further typing should result in recomputing
	 * this list
	 */
	isIncomplete: bool

	/*
	 * The completion items
	 */
	items*: CompletionItem
}

type CompletionItem {
	/*
	 * The label of this completion item By default
	 * also the text that is inserted when selecting
	 * this completion
	 */
	label: string

	/*
	 * The kind of this completion item Based of the kind
	 * an icon is chosen by the editor The standardized set
	 * of available values is defined in `CompletionItemKind`
	 */
	kind?: int

	/*
	 * A human-readable string with additional information
	 * about this item, like type or symbol information
	 */
	detail?: string

	/*
	 * A human-readable string that represents a doc-comment
	 */
	documentation?: string | MarkupContent

	/*
	 * Indicates if this item is deprecated
	 */
	deprecated?: bool

	/*
	 * Select this item when showing
	 *
	 * *Note* that only one completion item can be selected and that the
	 * tool / client decides which item that is The rule is that the *first*
	 * item of those that match best is selected
	 */
	preselect?: bool

	/*
	 * A string that should be used when comparing this item
	 * with other items When `falsy` the label is used
	 */
	sortText?: string

	/*
	 * A string that should be used when filtering a set of
	 * completion items When `falsy` the label is used
	 */
	filterText?: string

	/*
	 * A string that should be inserted into a document when selecting
	 * this completion When `falsy` the label is used
	 *
	 * The `insertText` is subject to interpretation by the client side
	 * Some tools might not take the string literally For example
	 * VS Code when code complete is requested in this example `con<cursor position>`
	 * and a completion item with an `insertText` of `console` is provided it
	 * will only insert `sole` Therefore it is recommended to use `textEdit` instead
	 * since it avoids additional client side interpretation
	 *
	 * @deprecated Use textEdit instead
	 */
	insertText?: string

	/*
	 * The format of the insert text The format applies to both the `insertText` property
	 * and the `newText` property of a provided `textEdit`
	 */
	insertTextFormat?: int //namespace: 1 = plainText, 2 = Snippet

	/*
	 * An edit which is applied to a document when selecting this completion When an edit is provided the value of
	 * `insertText` is ignored
	 *
	 * *Note:* The range of the edit must be a single line range and it must contain the position at which completion
	 * has been requested
	 */
	textEdit?: TextEdit

	/*
	 * An optional array of additional text edits that are applied when
	 * selecting this completion Edits must not overlap (including the same insert position)
	 * with the main edit nor with themselves
	 *
	 * Additional text edits should be used to change text unrelated to the current cursor position
	 * (for example adding an import statement at the top of the file if the completion item will
	 * insert an unqualified type)
	 */
	additionalTextEdits?: TextEdit

	/*
	 * An optional set of characters that when pressed while this completion is active will accept it first and
	 * then type that character *Note* that all commit characters should have `length=1` and that superfluous
	 * characters will be ignored
	 */
	commitCharacters*: string

	/*
	 * An optional command that is executed *after* inserting this completion *Note* that
	 * additional modifications to the current document should be described with the
	 * additionalTextEdits-property
	 */
	command?: Command

	/*
	 * A data entry field that is preserved on a completion item between
	 * a completion and a completion resolve request
	 */
	data?: any
}

/*
 * A `MarkupContent` literal represents a string value which content is interpreted base on its
 * kind flag Currently the protocol supports `plaintext` and `markdown` as markup kinds
 *
 * If the kind is `markdown` then the value can contain fenced code blocks like in GitHub issues
 * See https://helpgithubcom/articles/creating-and-highlighting-code-blocks/#syntax-highlighting
 *
 * Here is an example how such a string can be constructed using JavaScript / TypeScript:
 * ```typescript
 * let markdown: MarkdownContent = {
 *  kind: MarkupKindMarkdown,
 *	value: [
 *		'# Header',
 *		'Some text',
 *		'```typescript',ol INFO: [server.ol] [JSON-RPC debug] Receiving: {"jsonrpc":"2.
 *		'someCode()',
 *		'```'
 *	]join('\n')
 * }
  * ```
 *
 * *Please Note* that clients might sanitize the return markdown A client could decide to
 * remove HTML from the markdown to avoid script execution
 */
type MarkupContent {
	kind: undefined
	value: string
}

type Command {
	title: string
	command: string
	arguments*: undefined
}

type DidChangeWatchedFilesParams {
	changes[1,*]: FileEvent
}

type FileEvent {
	uri: DocumentUri
	/*
	 * 1 = created, 2 = Changed, 3 = Deleted
	 */
	type: int
}

type DidChangeWorkspaceFoldersParams {
	event: WorkspaceFolderChangeEvent
}

type WorkspaceFolderChangeEvent {
	added[1,*]: WorkspaceFolder
	removed[1,*]: WorkspaceFolder
}

type DidChangeConfigurationParams {
	settings: undefined
}

type WorkspaceSymbolParams {
	query: string
	workDoneToken?: int | string
	partialResultToken?: int | string
}

type WorkSpaceSymbolResponse {_*: SymbolInformation | WorkspaceSymbol}

type WorkspaceSymbol {
	name: string
	kind: SymbolKind
	tags?: undefined
	location: Location | DocumentUri
	containerName?: string
}

type SymbolInformation {
	/*
	 * The name of this symbol
	 */
	name: string
	/*
	 * The kind of this symbol
	 */
	kind: int
	/*
	 * Indicates if this symbol is deprecated
	 */
	deprecated?: bool
	/*
	 * The location of this symbol The location's range is used by a tool
	 * to reveal the location in the editor If the symbol is selected in the
	 * tool the range's start information is used to position the cursor So
	 * the range usually spans more then the actual symbol's name and does
	 * normally include things like visibility modifiers
	 *
	 * The range doesn't have to denote a node range in the sense of a abstract
	 * syntax tree It can therefore not be used to re-construct a hierarchy of
	 * the symbols
	 */
	location: Location

	/*
	 * The name of the symbol containing this symbol This information is for
	 * user interface purposes (eg to render a qualifier in the user interface
	 * if necessary) It can't be used to re-infer a hierarchy for the document
	 * symbols
	 */
	containerName?: string
}

type DocumentSymbolResult {
	_*: SymbolInformation
}

type Location {
	uri: DocumentUri
	range: Range
}

type ExecuteCommandParams {
	command: string
	arguments*: undefined
}

type ExecuteCommandResult: undefined

type Hover {
	contents[1,*]: MarkedString | MarkupContent
	range?: Range
}

type HoverInformations: Hover | void

type DefinitionResponse: Location | void

type MarkedString: string | MarkSt

type MarkSt {
	language: string
	value: string
}

type DiagnosticParams {
	uri: DocumentUri

	/**
	 * Optional the version number of the document the diagnostics are published
	 * for.
	 *
	 * @since 3.15.0
	 */
	version?: int

	diagnostics*: Diagnostic | void
}

type Diagnostic {
	range: Range
	severity?: int //1=error, 2=warn, 3=info, 4=hint
	code?: int | string
	/**
	 * An optional property to describe the error code.
	 *
	 * @since 3.16.0
	 */
	codeDescription? {
		/**
		* An URI to open with more information about the diagnostic error.
		*/
		href: string
	}
	source?: string
	message: string
	/**
	 * Additional metadata about the diagnostic.
	 *
	 * @since 3.15.0
	 */
	tags*: int
	relatedInformation*: DiagnosticRelatedInformation
}

type DiagnosticRelatedInformation {
	location: Location
	message: string
}

type DocumentSymbolParams {
	textDocument: TextDocumentIdentifier
}

type Snippet: string {
	prefix: string
	body: string
}

type TextDocument {
	uri: string
	lines*: string
	source: string
	version: int
	jolieProgram?: undefined
}

type DocumentModifications {
	version: int
	uri: string
	text: string
}

type DocumentData {
	uri: string
	text: string
}

type RenameRequest {
	newName: string
	textDocument {
		uri: DocumentUri
	}
	position {
		character: int
		line: int
	}
}

// https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspaceEdit
// workspaceEdit
/* type WorkspaceEditResponse {
	changes? {
		_uri*: DocumentUri {
			_textEdit*: TextEdit
		}
	}
} */

//should be WorkspaceEditResponse
type RenameResponse: undefined | void

type setTraceReq {
	value: string
}

interface GeneralInterface {
	OneWay:
		initialized( InitializedParams ),
    	onExit( void ),
    	cancelRequest,
    	setTrace(setTraceReq)
	RequestResponse:
    	initialize( InitializeParams )( InitializeResult ),
    	shutdown( void )( void )
}
interface GlobalVariables {
	RequestResponse:
		getRootUri(void)(DocumentUri)
}

interface TextDocumentInterface {
	OneWay:
		didOpen( DidOpenTextDocumentParams ),
		didChange( DidChangeTextDocumentParams ),
		willSave( WillSaveTextDocumentParams ),
		didSave( DidSaveTextDocumentParams ),
		didClose( DidCloseTextDocumentParams )
	RequestResponse:
		willSaveWaitUntil( WillSaveTextDocumentParams )( WillSaveWaitUntilResponse ),
		completion( CompletionParams )( CompletionResult ),
		hover( TextDocumentPositionParams )( HoverInformations ),
		documentSymbol( DocumentSymbolParams )( DocumentSymbolResult ),
		signatureHelp( TextDocumentPositionParams )( SignatureHelpResponse ), //TODO check LSP
		definition(TextDocumentPositionParams)(DefinitionResponse),
		rename(RenameRequest)(RenameResponse)
}

interface WorkspaceInterface {
	OneWay:
		didChangeWatchedFiles( DidChangeWatchedFilesParams ),
		didChangeWorkspaceFolders( DidChangeWorkspaceFoldersParams ),
		didChangeConfiguration( DidChangeConfigurationParams )
	RequestResponse:
		symbol( WorkspaceSymbolParams )( WorkSpaceSymbolResponse ),
		executeCommand( ExecuteCommandParams )( ExecuteCommandResult )
}

interface ServerToClient {
	OneWay:
		publishDiagnostics( DiagnosticParams )
}

interface UtilsInterface {
	RequestResponse:
		getDocument( string )( TextDocument )
	OneWay:
		insertNewDocument( DidOpenTextDocumentParams ),
		updateDocument( DocumentModifications ),
		deleteDocument( DidCloseTextDocumentParams )
}

type CreationResponse {
	filename: string
	includePaths*: string
	source: string
}

interface InspectionUtilsInterface {
	RequestResponse:
		inspectDocument( DocumentData )(undefined),
		inspectDocumentReturnDiagnostics( DocumentData)( DiagnosticParams),
		createMinimalInspectionRequest(DocumentData)(CreationResponse)
}

type CompletionImportSymbolRequest: any {
	regexMatch*:string
	txtDocUri:string
}
type CompletionImportSymbolResult: any {
	result*:string
}

type CompletionImportModuleRequest: any {
	regexMatch*:string
	txtDocUri:string
}

type CompletionImportModuleResult: any {
	result*:string
}

type CompletionOperationRequest: any {
	codeLine:string
	jolieProgram?:undefined
}

type CompletionOperationResult: any {
	result*:CompletionItem
}

type CompletionKeywordRequest: any {
	codeLine:string
}

type CompletionKeywordResult: any {
	result*:CompletionItem
}

interface CompletionHelperInterface {
	RequestResponse:
		completionOperation(CompletionOperationRequest)(CompletionOperationResult),
		completionKeywords(CompletionKeywordRequest)(CompletionKeywordResult),
		completionImportModule(CompletionImportModuleRequest)(CompletionImportModuleResult),
		completionImportSymbol(CompletionImportSymbolRequest)(CompletionImportSymbolResult)
}
