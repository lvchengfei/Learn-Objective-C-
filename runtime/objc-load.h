<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc-load.h</title>
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
<h1 style="margin:8px;" id="f1">objc-load.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
 *	objc-load.h
 *	Copyright 1988-1996, NeXT Software, Inc.
 */</span>

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">_OBJC_LOAD_H_</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_OBJC_LOAD_H_</span>

#<span class="enscript-reference">if</span> !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NeXT_PDO</span>)
#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">objc</span>/<span class="enscript-variable-name">objc</span>-<span class="enscript-variable-name">class</span>.<span class="enscript-variable-name">h</span>&gt;

#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">mach</span>-<span class="enscript-variable-name">o</span>/<span class="enscript-variable-name">loader</span>.<span class="enscript-variable-name">h</span>&gt;

<span class="enscript-comment">/* dynamically loading Mach-O object files that contain Objective-C code */</span>

OBJC_EXPORT <span class="enscript-type">long</span> <span class="enscript-function-name">objc_loadModules</span> (
	<span class="enscript-type">char</span> *modlist[], 
	<span class="enscript-type">void</span> *errStream,
	<span class="enscript-type">void</span> (*class_callback) (Class, Category),
	<span class="enscript-comment">/*headerType*/</span> <span class="enscript-type">struct</span> mach_header **hdr_addr,
	<span class="enscript-type">char</span> *debug_file
);
OBJC_EXPORT <span class="enscript-type">int</span> <span class="enscript-function-name">objc_loadModule</span> (
	<span class="enscript-type">char</span> *	moduleName, 
	<span class="enscript-type">void</span>	(*class_callback) (Class, Category),
	<span class="enscript-type">int</span> *	errorCode);
OBJC_EXPORT <span class="enscript-type">long</span> <span class="enscript-function-name">objc_unloadModules</span>(
	<span class="enscript-type">void</span> *errorStream,				<span class="enscript-comment">/* input (optional) */</span>
	<span class="enscript-type">void</span> (*unloadCallback)(Class, Category)		<span class="enscript-comment">/* input (optional) */</span>
);

OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">objc_register_header_name</span>(
	<span class="enscript-type">char</span> *name					<span class="enscript-comment">/* input */</span>
);

OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">objc_register_header</span>(
	<span class="enscript-type">char</span> *name					<span class="enscript-comment">/* input */</span>
);

#<span class="enscript-reference">endif</span> <span class="enscript-variable-name">NeXT_PDO</span>
#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* _OBJC_LOAD_H_ */</span>
</pre>
<hr />
</body></html>