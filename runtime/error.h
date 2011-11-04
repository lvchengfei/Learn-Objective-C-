<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>error.h</title>
<style type="text/css">
.enscript-comment { font-style: italic; color: rgb(178,34,34); }
.enscript-function-name { font-weight: bold; color: rgb(0,0,255); }
.enscript-variable-name { font-weight: bold; color: rgb(184,134,11); }
.enscript-keyword { font-weight: bold; color: rgb(160,32,240); }
.enscript-reference { font-weight: bold; color: rgb(95,158,160); }
.enscript-string { font-weight: bold; color: rgb(188,143,143); }
.enscript-builtin { font-weight: bold; color: rgb(218,112,214); }
.enscript-type { font-weight: bold; color: rgb(34,139,34); }
.enscript-highlight { text-decoration: underline; color: 0; }
</style>
</head>
<body id="top">
<h1 style="margin:8px;" id="f1">error.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
<hr/>
<div></div>
<pre>
<span class="enscript-comment">/*
 * Copyright (c) 1999 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * Portions Copyright (c) 1999 Apple Computer, Inc.  All Rights
 * Reserved.  This file contains Original Code and/or Modifications of
 * Original Code as defined in and that are subject to the Apple Public
 * Source License Version 1.1 (the &quot;License&quot;).  You may not use this file
 * except in compliance with the License.  Please obtain a copy of the
 * License at <a href="http://www.apple.com/publicsource">http://www.apple.com/publicsource</a> and read it before using
 * this file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an &quot;AS IS&quot; basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */</span>

<span class="enscript-comment">/*
    error.h

    This file defines the interface to the exception raising scheme.

    Copyright (c) 1988-1996 NeXT Software, Inc. as an unpublished work.
    All rights reserved.
*/</span>

#<span class="enscript-reference">warning</span> <span class="enscript-variable-name">the</span> <span class="enscript-variable-name">API</span> <span class="enscript-variable-name">in</span> <span class="enscript-variable-name">this</span> <span class="enscript-variable-name">header</span> <span class="enscript-variable-name">is</span> <span class="enscript-variable-name">obsolete</span>

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">_OBJC_ERROR_H_</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_OBJC_ERROR_H_</span>

#<span class="enscript-reference">include</span> <span class="enscript-string">&lt;setjmp.h&gt;</span>
#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">objc</span>/<span class="enscript-variable-name">objc</span>-<span class="enscript-variable-name">api</span>.<span class="enscript-variable-name">h</span>&gt;

#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__svr4__</span>)
    #define _setjmp setjmp
    #define _longjmp longjmp
#<span class="enscript-reference">endif</span>

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> _NXHandler {	<span class="enscript-comment">/* a node in the handler chain */</span>
    jmp_buf jumpState;			<span class="enscript-comment">/* place to longjmp to */</span>
    <span class="enscript-type">struct</span> _NXHandler *next;		<span class="enscript-comment">/* ptr to next handler */</span>
    <span class="enscript-type">int</span> code;				<span class="enscript-comment">/* error code of exception */</span>
    <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data1, *data2;		<span class="enscript-comment">/* blind data for describing error */</span>
} NXHandler;


<span class="enscript-comment">/* Handles RAISE's with nowhere to longjmp to */</span>
<span class="enscript-type">typedef</span> <span class="enscript-type">void</span> <span class="enscript-function-name">NXUncaughtExceptionHandler</span>(<span class="enscript-type">int</span> code, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data1,
						<span class="enscript-type">const</span> <span class="enscript-type">void</span> *data2);
OBJC_EXPORT NXUncaughtExceptionHandler *_NXUncaughtExceptionHandler;
#<span class="enscript-reference">define</span> <span class="enscript-function-name">NXGetUncaughtExceptionHandler</span>() _NXUncaughtExceptionHandler
#<span class="enscript-reference">define</span> <span class="enscript-function-name">NXSetUncaughtExceptionHandler</span>(proc) \
			(_NXUncaughtExceptionHandler = (proc))

<span class="enscript-comment">/* NX_DURING, NX_HANDLER and NX_ENDHANDLER are always used like:

	NX_DURING
	    some code which might raise an error
	NX_HANDLER
	    code that will be jumped to if an error occurs
	NX_ENDHANDLER

   If any error is raised within the first block of code, the second block
   of code will be jumped to.  Typically, this code will clean up any
   resources allocated in the routine, possibly case on the error code
   and perform special processing, and default to RERAISE the error to
   the next handler.  Within the scope of the handler, a local variable
   called NXLocalHandler of type NXHandler holds information about the
   error raised.

   It is illegal to exit the first block of code by any other means than
   NX_VALRETURN, NX_VOIDRETURN, or just falling out the bottom.
 */</span>

<span class="enscript-comment">/* private support routines.  Do not call directly. */</span>
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">_NXAddHandler</span>( NXHandler *handler );
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">_NXRemoveHandler</span>( NXHandler *handler );

#<span class="enscript-reference">define</span> <span class="enscript-variable-name">NX_DURING</span> { NXHandler NXLocalHandler;			\
		    _NXAddHandler(&amp;NXLocalHandler);		\
		    <span class="enscript-keyword">if</span>( !_setjmp(NXLocalHandler.jumpState) ) {

#<span class="enscript-reference">define</span> <span class="enscript-variable-name">NX_HANDLER</span> _NXRemoveHandler(&amp;NXLocalHandler); } else {

#<span class="enscript-reference">define</span> <span class="enscript-variable-name">NX_ENDHANDLER</span> }}

#<span class="enscript-reference">define</span> <span class="enscript-function-name">NX_VALRETURN</span>(val)  do { typeof(val) temp = (val);	\
			_NXRemoveHandler(&amp;NXLocalHandler);	\
			<span class="enscript-keyword">return</span>(temp); } <span class="enscript-keyword">while</span> (0)

#<span class="enscript-reference">define</span> <span class="enscript-variable-name">NX_VOIDRETURN</span>	do { _NXRemoveHandler(&amp;NXLocalHandler);	\
			<span class="enscript-keyword">return</span>; } <span class="enscript-keyword">while</span> (0)

<span class="enscript-comment">/* RAISE and RERAISE are called to indicate an error condition.  They
   initiate the process of jumping up the chain of handlers.
 */</span>

OBJC_EXPORT
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__GNUC__</span>) &amp;&amp; !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__STRICT_ANSI__</span>) &amp;&amp; !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NeXT_PDO</span>)
    <span class="enscript-type">volatile</span>	<span class="enscript-comment">/* never returns */</span>
#<span class="enscript-reference">endif</span> 
<span class="enscript-type">void</span> <span class="enscript-function-name">_NXRaiseError</span>(<span class="enscript-type">int</span> code, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data1, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data2)
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__GNUC__</span>)
  __attribute__ ((noreturn))
#<span class="enscript-reference">endif</span>
;

#<span class="enscript-reference">define</span> <span class="enscript-function-name">NX_RAISE</span>( code, data1, data2 )	\
		_NXRaiseError( (code), (data1), (data2) )

#<span class="enscript-reference">define</span> <span class="enscript-function-name">NX_RERAISE</span>() 	_NXRaiseError( NXLocalHandler.code,	\
				NXLocalHandler.data1, NXLocalHandler.data2 )

<span class="enscript-comment">/* These routines set and return the procedure which is called when
   exceptions are raised.  This procedure must NEVER return.  It will
   usually either longjmp, or call the uncaught exception handler.
   The default exception raiser is also declared
 */</span>
<span class="enscript-type">typedef</span> <span class="enscript-type">volatile</span> <span class="enscript-type">void</span> <span class="enscript-function-name">NXExceptionRaiser</span>(<span class="enscript-type">int</span> code, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data1, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data2);
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">NXSetExceptionRaiser</span>(NXExceptionRaiser *proc);
OBJC_EXPORT NXExceptionRaiser *<span class="enscript-function-name">NXGetExceptionRaiser</span>(<span class="enscript-type">void</span>);
OBJC_EXPORT NXExceptionRaiser NXDefaultExceptionRaiser;


<span class="enscript-comment">/* The error buffer is used to allocate data which is passed up to other
   handlers.  Clients should clear the error buffer in their top level
   handler.  The Application Kit does this.
 */</span>
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">NXAllocErrorData</span>(<span class="enscript-type">int</span> size, <span class="enscript-type">void</span> **data);
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">NXResetErrorData</span>(<span class="enscript-type">void</span>);

#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* _OBJC_ERROR_H_ */</span>
</pre>
<hr />
</body></html>