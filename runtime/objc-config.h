<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc-config.h</title>
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
<h1 style="margin:8px;" id="f1">objc-config.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
</span><span class="enscript-comment">// objc-config.h created by kthorup on Fri 24-Mar-1995
</span>
<span class="enscript-comment">// OBJC_INSTRUMENTED controls whether message dispatching is dynamically
</span><span class="enscript-comment">// monitored.  Monitoring introduces substantial overhead.
</span><span class="enscript-comment">// NOTE: To define this condition, do so in the build command, NOT by
</span><span class="enscript-comment">// uncommenting the line here.  This is because objc-class.h heeds this
</span><span class="enscript-comment">// condition, but objc-class.h can not #import this file (objc-config.h)
</span><span class="enscript-comment">// because objc-class.h is public and objc-config.h is not.
</span><span class="enscript-comment">//#define OBJC_INSTRUMENTED
</span>
<span class="enscript-comment">// OBJC_COLLECTING_CACHE controls whether the method dispatching caches
</span><span class="enscript-comment">// are lockless during dispatch.  This is a BIG speed win, but can be
</span><span class="enscript-comment">// implemented only when a thread can figure out the PCs of all the other
</span><span class="enscript-comment">// threads in the task.
</span>
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">hppa</span>) || <span class="enscript-variable-name">defined</span> (<span class="enscript-variable-name">__i386__</span>) || <span class="enscript-variable-name">defined</span> (<span class="enscript-variable-name">i386</span>) || <span class="enscript-variable-name">defined</span> (<span class="enscript-variable-name">m68k</span>) || <span class="enscript-variable-name">defined</span> (<span class="enscript-variable-name">__ppc__</span>) || <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">ppc</span>)
    #<span class="enscript-keyword">if</span> !defined(NeXT_PDO)
        #define OBJC_COLLECTING_CACHE
    #endif
#<span class="enscript-reference">endif</span>

<span class="enscript-comment">// Turn on support for class refs
</span>#<span class="enscript-reference">define</span> <span class="enscript-variable-name">OBJC_CLASS_REFS</span>

    #define __S(x) x

#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NeXT_PDO</span>)
    #define GENERIC_OBJC_FILE
#<span class="enscript-reference">endif</span>

<span class="enscript-comment">// Get the nice macros for subroutine calling, etc.
</span><span class="enscript-comment">// Not available on all architectures.  Not needed
</span><span class="enscript-comment">// (by us) on some configurations.
</span>#<span class="enscript-reference">if</span> <span class="enscript-variable-name">defined</span> (<span class="enscript-variable-name">__i386__</span>) || <span class="enscript-variable-name">defined</span> (<span class="enscript-variable-name">i386</span>)
    #import &lt;architecture/i386/asm_help.h&gt;
#<span class="enscript-reference">elif</span> <span class="enscript-variable-name">defined</span> (<span class="enscript-variable-name">__ppc__</span>) || <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">ppc</span>)
    #import &lt;architecture/ppc/asm_help.h&gt;
#<span class="enscript-reference">elif</span> (!<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">hppa</span>) &amp;&amp; !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">sparc</span>)) || !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NeXT_PDO</span>)
    #error We need asm_help.h <span class="enscript-keyword">for</span> this architecture
#<span class="enscript-reference">endif</span>
</pre>
<hr />
</body></html>