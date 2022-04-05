/*
 * Copyright (C) 2019 Saverio Giallorenzo <saverio.giallorenzo@gmail.com>
 * Copyright (C) 2019 Fabrizio Montesi <famontesi@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

from types.JavaException import WeakJavaExceptionType
//from types.CodeCheckException import CodeCheckExceptionType

type LineInterval {
    .start:int
    .end:int
}

type ColumnInterval {
    start:int
    end:int
}

type Context {
	.startColumn:int
	.endColumn:int
	.startLine:int
	.endLine:int
}

type CodeCheckMessage {
	.context?:Context
	.description?:string
	.help?:string
}

type CodeCheckExceptionType {
    .exceptions*:CodeCheckMessage
}

type Field {
	name: string
	range {
		min:int
		max:int
	}
	type: TypeInfo
}

type TypeInfo:
void {
	documentation?: string
	linkedTypeName: string
}
|
// Inline type definition
void {
	documentation?: string
	nativeType: string
	fields*: Field
	untypedFields: bool
}
|
// Type choice
void {
	documentation?: string
	left: TypeInfo
	right: TypeInfo
}

type FaultInfo {
	name: string
	type: string
}

type OperationInfo {
	name: string
	requestType: string
	responseType?: string
	faults*: FaultInfo
	documentation?: string
}

type InterfaceInfo {
	name: string
	operations*: OperationInfo
	documentation?: string
}

type PortInfo {
	name: string
	location?: string
	protocol?: string
	interfaces*: InterfaceInfo
	documentation?: string
}

type TypeDefinition {
	name: string
	type: TypeInfo
}

type PortInspectionResponse {
	inputPorts*: PortInfo
	outputPorts*: PortInfo
	referredTypes*: TypeDefinition
}

type TypesInspectionResponse {
	types*: TypeDefinition
}

type FileInspectionResponse{
	inputPorts*: PortInfo
	outputPorts*: PortInfo
	referredTypes*: TypeDefinition
}

type InspectionRequest {
	filename: string
	includePaths*: string
	source?: string
}
type ModuleInspectionRequest {
	filename: string
	includePaths*: string
	source: string
	position: Position
}

type Position {
	character: int
	line: int
}

type ModuleInspectionResponse {
	module?: string {
		name: string 
		context {
			startLine: int
			endLine: int
			startColumn: int
			endColumn: int
		}
		
	}
}

type WorkspaceModulesInspectionRequest {
	rootUri: string
	includePaths*: string
	symbol: string
}

type InspectionToRenameRequest {
	newName: string
	textDocument{
		uri: string
	}
	position{
		character:int
		line: int
	}
	rootUri: string
	includePaths*: string
}

type MoreSymbolsPerModule{
	module*: string {
		symbol*: string {
			context {
				startLine: int
				endLine: int
				startColumn: int
				endColumn: int
			}
		}
	}
}

interface InspectorInterface {
RequestResponse:
	// general inspection
	inspectFile(InspectionRequest)(FileInspectionResponse)
		throws	CodeCheckException(CodeCheckExceptionType)
						FileNotFoundException( WeakJavaExceptionType )
						IOException( WeakJavaExceptionType ),
	// not used at the moment
	inspectPorts( InspectionRequest )( PortInspectionResponse )
		throws	ParserException( WeakJavaExceptionType )
						SemanticException( WeakJavaExceptionType )
						FileNotFoundException( WeakJavaExceptionType )
						IOException( WeakJavaExceptionType ),
	//not used at the moment
	inspectTypes( InspectionRequest )( TypesInspectionResponse )
		throws	ParserException( WeakJavaExceptionType )
						SemanticException( WeakJavaExceptionType )
						FileNotFoundException( WeakJavaExceptionType )
						IOException( WeakJavaExceptionType ),
	inspectModule(ModuleInspectionRequest)(ModuleInspectionResponse),
	inspectWorkspaceModules(WorkspaceModulesInspectionRequest)(MoreSymbolsPerModule),
	inspectionToRename(InspectionToRenameRequest)(MoreSymbolsPerModule)
		throws FaultException(WeakJavaExceptionType),
	// used for codeLens
	getModuleSymbols(InspectionRequest)(MoreSymbolsPerModule)
}

service Inspector {
    inputPort ip {
        location:"local"
        interfaces: InspectorInterface
    }

    foreign java {
        class: "inspector.Inspector"
    }
}
