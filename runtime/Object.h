<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Object.h</title>
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
<h1 style="margin:8px;" id="f1">Object.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
	Object.h
	Copyright 1988-1996 NeXT Software, Inc.
  
	DEFINED AS:	A common class
	HEADER FILES:	&lt;objc/Object.h&gt;

*/</span>

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">_OBJC_OBJECT_H_</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_OBJC_OBJECT_H_</span>

#<span class="enscript-reference">include</span> <span class="enscript-string">&lt;objc/objc-runtime.h&gt;</span>

@class Protocol;

@interface Object
{
	Class isa;	<span class="enscript-comment">/* A pointer to the instance's class structure */</span>
}

<span class="enscript-comment">/* Initializing classes and instances */</span>

+ initialize;
- init;

<span class="enscript-comment">/* Creating, copying, and freeing instances */</span>

+ new;
+ free;
- free;
+ alloc;
- copy;
+ allocFromZone:(<span class="enscript-type">void</span> *)zone;
- copyFromZone:(<span class="enscript-type">void</span> *)zone;
- (<span class="enscript-type">void</span> *)zone;

<span class="enscript-comment">/* Identifying classes */</span>

+ class;
+ superclass;
+ (<span class="enscript-type">const</span> <span class="enscript-type">char</span> *) name;
- class;
- superclass;
- (<span class="enscript-type">const</span> <span class="enscript-type">char</span> *) name;

<span class="enscript-comment">/* Identifying and comparing instances */</span>

- self;
- (<span class="enscript-type">unsigned</span> <span class="enscript-type">int</span>) hash;
- (BOOL) isEqual:anObject;

<span class="enscript-comment">/* Testing inheritance relationships */</span>

- (BOOL) isKindOf: aClassObject;
- (BOOL) isMemberOf: aClassObject;
- (BOOL) isKindOfClassNamed: (<span class="enscript-type">const</span> <span class="enscript-type">char</span> *)aClassName;
- (BOOL) isMemberOfClassNamed: (<span class="enscript-type">const</span> <span class="enscript-type">char</span> *)aClassName;

<span class="enscript-comment">/* Testing class functionality */</span>

+ (BOOL) instancesRespondTo:(SEL)aSelector;
- (BOOL) respondsTo:(SEL)aSelector;

<span class="enscript-comment">/* Testing protocol conformance */</span>

- (BOOL) conformsTo: (Protocol *)aProtocolObject;
+ (BOOL) conformsTo: (Protocol *)aProtocolObject;

<span class="enscript-comment">/* Obtaining method descriptors from protocols */</span>

- (<span class="enscript-type">struct</span> objc_method_description *) descriptionForMethod:(SEL)aSel;
+ (<span class="enscript-type">struct</span> objc_method_description *) descriptionForInstanceMethod:(SEL)aSel;

<span class="enscript-comment">/* Obtaining method handles */</span>

- (IMP) methodFor:(SEL)aSelector;
+ (IMP) instanceMethodFor:(SEL)aSelector;

<span class="enscript-comment">/* Sending messages determined at run time */</span>

- perform:(SEL)aSelector;
- perform:(SEL)aSelector with:anObject;
- perform:(SEL)aSelector with:object1 with:object2;

<span class="enscript-comment">/* Posing */</span>

+ poseAs: aClassObject;

<span class="enscript-comment">/* Enforcing intentions */</span>
 
- subclassResponsibility:(SEL)aSelector;
- notImplemented:(SEL)aSelector;

<span class="enscript-comment">/* Error handling */</span>

- doesNotRecognize:(SEL)aSelector;
- error:(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *)aString, ...;

<span class="enscript-comment">/* Debugging */</span>

- (<span class="enscript-type">void</span>) printForDebugger:(<span class="enscript-type">void</span> *)stream;

<span class="enscript-comment">/* Archiving */</span>

- awake;
- write:(<span class="enscript-type">void</span> *)stream;
- read:(<span class="enscript-type">void</span> *)stream;
+ (<span class="enscript-type">int</span>) version;
+ setVersion: (<span class="enscript-type">int</span>) aVersion;

<span class="enscript-comment">/* Forwarding */</span>

- forward: (SEL)sel : (marg_list)args;
- performv: (SEL)sel : (marg_list)args;

@end

<span class="enscript-comment">/* Abstract Protocol for Archiving */</span>

@interface Object (Archiving)

- startArchiving: (<span class="enscript-type">void</span> *)stream;
- finishUnarchiving;

@end

<span class="enscript-comment">/* Abstract Protocol for Dynamic Loading */</span>

#<span class="enscript-reference">if</span> !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NeXT_PDO</span>)
@interface Object (DynamicLoading)

<span class="enscript-comment">//+ finishLoading:(headerType *)header;
</span>+ finishLoading:(<span class="enscript-type">struct</span> mach_header *)header;
+ startUnloading;

@end
#<span class="enscript-reference">endif</span>

OBJC_EXPORT id <span class="enscript-function-name">object_dispose</span>(Object *anObject);
OBJC_EXPORT id <span class="enscript-function-name">object_copy</span>(Object *anObject, <span class="enscript-type">unsigned</span> nBytes);
OBJC_EXPORT id <span class="enscript-function-name">object_copyFromZone</span>(Object *anObject, <span class="enscript-type">unsigned</span> nBytes, <span class="enscript-type">void</span> *z);
OBJC_EXPORT id <span class="enscript-function-name">object_realloc</span>(Object *anObject, <span class="enscript-type">unsigned</span> nBytes);
OBJC_EXPORT id <span class="enscript-function-name">object_reallocFromZone</span>(Object *anObject, <span class="enscript-type">unsigned</span> nBytes, <span class="enscript-type">void</span> *z);

#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* _OBJC_OBJECT_H_ */</span>
</pre>
<hr />
</body></html>