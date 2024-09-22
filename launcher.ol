#!/usr/bin/env jolie

/*
MIT License

Copyright (c) 2021 Fabrizio Montesi <famontesi@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

from runtime import Runtime
from file import File

service Launcher {
	embed Runtime as runtime
	embed File as file

	main {
		if ( is_defined( args[0] ) ) {
			port = args[0]
		} else {
			port = 8080
		}

		config.location = "socket://localhost:" + port

		getRealServiceDirectory@file()( home )
		getFileSeparator@file()( sep )
		loadLibrary@runtime(home + sep + "lib" + sep + "jolie-inspector-0.1.0.jar")()

		loadLibrary@runtime( home + sep + "lib" + sep + "jolie-inspector-0.1.0.jar" )()
		loadEmbeddedService@runtime( {
			filepath = home + sep + "main.ol"
			service = "Main"
			params -> config
		} )()

		linkIn( Shutdown )
	}
}
