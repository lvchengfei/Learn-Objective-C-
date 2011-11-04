<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc.h</title>
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
<h1 style="margin:8px;" id="f1">objc.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
 *	objc.h
 *	Copyright 1988-1996, NeXT Software, Inc.
 */</span>

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">_OBJC_OBJC_H_</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_OBJC_OBJC_H_</span>

#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">objc</span>/<span class="enscript-variable-name">objc</span>-<span class="enscript-variable-name">api</span>.<span class="enscript-variable-name">h</span>&gt;		// <span class="enscript-variable-name">for</span> <span class="enscript-variable-name">OBJC_EXPORT</span>

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> objc_class *Class;

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> objc_object {
	Class isa;
} *id;

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> objc_selector 	*SEL;    
<span class="enscript-type">typedef</span> <span class="enscript-function-name">id</span> 			(*IMP)(id, SEL, ...); 
<span class="enscript-type">typedef</span> <span class="enscript-type">char</span>			BOOL;

#<span class="enscript-reference">define</span> <span class="enscript-variable-name">YES</span>             (BOOL)1
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">NO</span>              (BOOL)0

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">Nil</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">Nil</span> 0		<span class="enscript-comment">/* id of Nil class */</span>
#<span class="enscript-reference">endif</span>

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">nil</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">nil</span> 0		<span class="enscript-comment">/* id of Nil instance */</span>
#<span class="enscript-reference">endif</span>


#<span class="enscript-reference">if</span> !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">STRICT_OPENSTEP</span>)

<span class="enscript-type">typedef</span> <span class="enscript-type">char</span> *STR;

OBJC_EXPORT BOOL <span class="enscript-function-name">sel_isMapped</span>(SEL sel);
OBJC_EXPORT <span class="enscript-type">const</span> <span class="enscript-type">char</span> *<span class="enscript-function-name">sel_getName</span>(SEL sel);
OBJC_EXPORT SEL <span class="enscript-function-name">sel_getUid</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *str);
OBJC_EXPORT SEL <span class="enscript-function-name">sel_registerName</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *str);
OBJC_EXPORT <span class="enscript-type">const</span> <span class="enscript-type">char</span> *<span class="enscript-function-name">object_getClassName</span>(id obj);
OBJC_EXPORT <span class="enscript-type">void</span> *<span class="enscript-function-name">object_getIndexedIvars</span>(id obj);

#<span class="enscript-reference">define</span> <span class="enscript-function-name">ISSELECTOR</span>(sel) sel_isMapped(sel)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">SELNAME</span>(sel)	sel_getName(sel)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">SELUID</span>(str)	sel_getUid(str)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">NAMEOF</span>(obj)     object_getClassName(obj)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">IV</span>(obj)         object_getIndexedIvars(obj)

#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__osf__</span>) &amp;&amp; <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__alpha__</span>)
    <span class="enscript-type">typedef</span> <span class="enscript-type">long</span> arith_t;
    <span class="enscript-type">typedef</span> <span class="enscript-type">unsigned</span> <span class="enscript-type">long</span> uarith_t;
    #define ARITH_SHIFT 32
#<span class="enscript-reference">else</span>
    <span class="enscript-type">typedef</span> <span class="enscript-type">int</span> arith_t;
    <span class="enscript-type">typedef</span> <span class="enscript-type">unsigned</span> uarith_t;
    #define ARITH_SHIFT 16
#<span class="enscript-reference">endif</span>

#<span class="enscript-reference">endif</span>	<span class="enscript-comment">/* !STRICT_OPENSTEP */</span>

#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* _OBJC_OBJC_H_ */</span>
</pre>
<hr />
</body></html>