<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc-api.h</title>
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
<h1 style="margin:8px;" id="f1">objc-api.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
<span class="enscript-comment">// Copyright 1988-1996 NeXT Software, Inc.
</span>
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">WIN32</span>)
    #<span class="enscript-keyword">if</span> defined(NSBUILDINGOBJC)
        #define OBJC_EXPORT __declspec(dllexport) <span class="enscript-type">extern</span>
    #<span class="enscript-keyword">else</span>
        #<span class="enscript-keyword">if</span> !defined(OBJC_EXPORT)
            #define OBJC_EXPORT __declspec(dllimport) <span class="enscript-type">extern</span>
        #endif
    #endif
    #<span class="enscript-keyword">if</span> !defined(OBJC_IMPORT)
        #define OBJC_IMPORT __declspec(dllimport) <span class="enscript-type">extern</span>
    #endif
#<span class="enscript-reference">endif</span>

#<span class="enscript-reference">if</span> !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">OBJC_EXPORT</span>)
    #define OBJC_EXPORT <span class="enscript-type">extern</span>
#<span class="enscript-reference">endif</span>

#<span class="enscript-reference">if</span> !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">OBJC_IMPORT</span>)
    #define OBJC_IMPORT <span class="enscript-type">extern</span>
#<span class="enscript-reference">endif</span>


<span class="enscript-comment">// obsolete
</span>#<span class="enscript-reference">if</span> !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NEXTPDO</span>)
    #<span class="enscript-keyword">if</span> defined(WIN32)
        #define NEXTPDO __declspec(dllimport) <span class="enscript-type">extern</span>
    #<span class="enscript-keyword">else</span>
        #define NEXTPDO <span class="enscript-type">extern</span>
    #endif
#<span class="enscript-reference">endif</span>
</pre>
<hr />
</body></html>