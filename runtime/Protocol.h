<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Protocol.h</title>
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
<h1 style="margin:8px;" id="f1">Protocol.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
	Protocol.h
	Copyright 1991-1996 NeXT Software, Inc.
*/</span>

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">_OBJC_PROTOCOL_H_</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_OBJC_PROTOCOL_H_</span>

#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">objc</span>/<span class="enscript-variable-name">Object</span>.<span class="enscript-variable-name">h</span>&gt;

<span class="enscript-type">struct</span> objc_method_description {
	SEL name;
	<span class="enscript-type">char</span> *types;
};
<span class="enscript-type">struct</span> objc_method_description_list {
        <span class="enscript-type">int</span> count;
        <span class="enscript-type">struct</span> objc_method_description list[1];
};

@interface Protocol : Object
{
@private
	<span class="enscript-type">char</span> *protocol_name;
 	<span class="enscript-type">struct</span> objc_protocol_list *protocol_list;
  	<span class="enscript-type">struct</span> objc_method_description_list *instance_methods, *class_methods;
#<span class="enscript-reference">ifdef</span> <span class="enscript-variable-name">NeXT_PDO</span>	<span class="enscript-comment">/* hppa needs 8 byte aligned protocol blocks */</span>
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__hpux__</span>) || <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">hpux</span>)
	<span class="enscript-type">unsigned</span> <span class="enscript-type">long</span>	risc_pad; 
#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* __hpux__ || hpux */</span>
#<span class="enscript-reference">endif</span> <span class="enscript-variable-name">NeXT_PDO</span>
}

<span class="enscript-comment">/* Obtaining attributes intrinsic to the protocol */</span>

- (<span class="enscript-type">const</span> <span class="enscript-type">char</span> *)name;

<span class="enscript-comment">/* Testing protocol conformance */</span>

- (BOOL) conformsTo: (Protocol *)aProtocolObject;

<span class="enscript-comment">/* Looking up information specific to a protocol */</span>

- (<span class="enscript-type">struct</span> objc_method_description *) descriptionForInstanceMethod:(SEL)aSel;
- (<span class="enscript-type">struct</span> objc_method_description *) descriptionForClassMethod:(SEL)aSel;

@end

#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* _OBJC_PROTOCOL_H_ */</span>
</pre>
<hr />
</body></html>