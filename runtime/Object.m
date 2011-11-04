<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Object.m</title>
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
<h1 style="margin:8px;" id="f1">Object.m&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
<hr/>
<div></div>
<pre>
/*
 * Copyright (c) 1999 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * Portions Copyright (c) 1999 Apple Computer, Inc.  All Rights
 * Reserved.  This file contains Original Code <span class="enscript-type">and</span>/<span class="enscript-type">or</span> Modifications of
 * Original Code as defined in <span class="enscript-type">and</span> that are subject to the Apple Public
 * Source License Version 1.1 (the &quot;License&quot;).  You may <span class="enscript-type">not</span> use this file
 * except in compliance with the License.  Please obtain a copy of the
 * License at <a href="http://www.apple.com/publicsource">http://www.apple.com/publicsource</a> <span class="enscript-type">and</span> read it before using
 * this file.
 * 
 * The Original Code <span class="enscript-type">and</span> <span class="enscript-type">all</span> software distributed under the License are
 * distributed on an &quot;AS IS&quot; basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.  Please see the
 * License <span class="enscript-keyword">for</span> the specific language governing rights <span class="enscript-type">and</span> limitations
 * under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */
/*
	Object.m
	Copyright 1988-1996 NeXT Software, Inc.
*/

#ifdef WINNT
#include &lt;winnt-pdo.h&gt;
#endif

#ifdef NeXT_PDO			// pickup BUG <span class="enscript-type">fix</span> flags
#import &lt;pdo.h&gt;
#endif

#import &lt;objc/Object.h&gt;
#import &quot;objc-private.h&quot;
#import &lt;objc/objc-runtime.h&gt;
#import &lt;objc/Protocol.h&gt;
#import &lt;stdarg.h&gt; 
#import &lt;string.h&gt; 

OBJC_EXPORT id (*_cvtToId)(const <span class="enscript-type">char</span> *);
OBJC_EXPORT id (*_poseAs)();

#define ISMETA(cls)		(((struct objc_class *)cls)-&gt;info &amp; CLS_META) 

// Error Messages
static const <span class="enscript-type">char</span>
	_errNoMem<span class="enscript-type">[</span><span class="enscript-type">]</span> = &quot;failed -- out of memory(<span class="enscript-comment">%s, %u)&quot;,
</span>	_errReAllocNil<span class="enscript-type">[</span><span class="enscript-type">]</span> = &quot;reallocating nil object&quot;,
	_errReAllocFreed<span class="enscript-type">[</span><span class="enscript-type">]</span> = &quot;reallocating freed object&quot;,
	_errReAllocTooSmall<span class="enscript-type">[</span><span class="enscript-type">]</span> = &quot;(<span class="enscript-comment">%s, %u) requested size too small&quot;,
</span>	_errShouldHaveImp<span class="enscript-type">[</span><span class="enscript-type">]</span> = &quot;should have implemented the <span class="enscript-string">'%s'</span> method.&quot;,
	_errShouldNotImp<span class="enscript-type">[</span><span class="enscript-type">]</span> = &quot;should NOT have implemented the <span class="enscript-string">'%s'</span> method.&quot;,
	_errLeftUndone<span class="enscript-type">[</span><span class="enscript-type">]</span> = &quot;method <span class="enscript-string">'%s'</span> <span class="enscript-type">not</span> implemented&quot;,
	_errBadSel<span class="enscript-type">[</span><span class="enscript-type">]</span> = &quot;method <span class="enscript-comment">%s given invalid selector %s&quot;,
</span>	_errDoesntRecognize<span class="enscript-type">[</span><span class="enscript-type">]</span> = &quot;does <span class="enscript-type">not</span> recognize selector <span class="enscript-comment">%c%s&quot;;
</span>

@implementation Object 


+ initialize
{
	<span class="enscript-keyword">return</span> self; 
}

- awake 
{
	<span class="enscript-keyword">return</span> self; 
}

+ poseAs: aFactory
{ 
	<span class="enscript-keyword">return</span> (*_poseAs)(self, aFactory); 
}

+ new
{
	id newObject = (*_alloc)((Class)self, 0);
	struct objc_class * metaClass = ((struct objc_class *) self)-&gt;<span class="enscript-type">isa</span>;
	<span class="enscript-keyword">if</span> (metaClass-&gt;<span class="enscript-type">version</span> &gt; 1)
	    <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>newObject init<span class="enscript-type">]</span>;
	<span class="enscript-keyword">else</span>
	    <span class="enscript-keyword">return</span> newObject;
}

+ alloc
{
	<span class="enscript-keyword">return</span> (*_zoneAlloc)((Class)self, 0, malloc_default_zone()); 
}

+ allocFromZone:(void *) z
{
	<span class="enscript-keyword">return</span> (*_zoneAlloc)((Class)self, 0, z); 
}

- init
{
    <span class="enscript-keyword">return</span> self;
}

- (const <span class="enscript-type">char</span> *)name
{
	<span class="enscript-keyword">return</span> ((struct objc_class *)<span class="enscript-type">isa</span>)-&gt;name; 
}

+ (const <span class="enscript-type">char</span> *)name
{
	<span class="enscript-keyword">return</span> ((struct objc_class *)self)-&gt;name; 
}

- (unsigned)hash
{
	<span class="enscript-keyword">return</span> ((uarith_t)self) &gt;&gt; 2;
}

- (BOOL)isEqual:anObject
{
	<span class="enscript-keyword">return</span> anObject == self; 
}

- free 
{ 
	<span class="enscript-keyword">return</span> (*_dealloc)(self); 
}

+ free
{
	<span class="enscript-keyword">return</span> nil; 
}

- self
{
	<span class="enscript-keyword">return</span> self; 
}

- <span class="enscript-type">class</span>
{
	<span class="enscript-keyword">return</span> (id)<span class="enscript-type">isa</span>; 
}

+ <span class="enscript-type">class</span> 
{
	<span class="enscript-keyword">return</span> self;
}

- (void *)zone
{
	void *z = malloc_zone_from_ptr(self);
	<span class="enscript-keyword">return</span> z ? z : malloc_default_zone();
}

+ superclass 
{ 
	<span class="enscript-keyword">return</span> ((struct objc_class *)self)-&gt;super_class; 
}

- superclass 
{ 
	<span class="enscript-keyword">return</span> ((struct objc_class *)<span class="enscript-type">isa</span>)-&gt;super_class; 
}

+ (int) <span class="enscript-type">version</span>
{
	struct objc_class *	<span class="enscript-type">class</span> = (struct objc_class *) self;
	<span class="enscript-keyword">return</span> <span class="enscript-type">class</span>-&gt;<span class="enscript-type">version</span>;
}

+ setVersion: (int) aVersion
{
	struct objc_class *	<span class="enscript-type">class</span> = (struct objc_class *) self;
	<span class="enscript-type">class</span>-&gt;<span class="enscript-type">version</span> = aVersion;
	<span class="enscript-keyword">return</span> self;
}

- (BOOL)isKindOf:aClass
{
	register Class cls;
	<span class="enscript-keyword">for</span> (cls = <span class="enscript-type">isa</span>; cls; cls = ((struct objc_class *)cls)-&gt;super_class) 
		<span class="enscript-keyword">if</span> (cls == (Class)aClass)
			<span class="enscript-keyword">return</span> YES;
	<span class="enscript-keyword">return</span> NO;
}

- (BOOL)isMemberOf:aClass
{
	<span class="enscript-keyword">return</span> <span class="enscript-type">isa</span> == (Class)aClass;
}

- (BOOL)isKindOfClassNamed:(const <span class="enscript-type">char</span> *)aClassName
{
	register Class cls;
	<span class="enscript-keyword">for</span> (cls = <span class="enscript-type">isa</span>; cls; cls = ((struct objc_class *)cls)-&gt;super_class) 
		<span class="enscript-keyword">if</span> (<span class="enscript-type">strcmp</span>(aClassName, ((struct objc_class *)cls)-&gt;name) == 0)
			<span class="enscript-keyword">return</span> YES;
	<span class="enscript-keyword">return</span> NO;
}

- (BOOL)isMemberOfClassNamed:(const <span class="enscript-type">char</span> *)aClassName 
{
	<span class="enscript-keyword">return</span> <span class="enscript-type">strcmp</span>(aClassName, ((struct objc_class *)<span class="enscript-type">isa</span>)-&gt;name) == 0;
}

+ (BOOL)instancesRespondTo:(SEL)aSelector 
{
	<span class="enscript-keyword">return</span> class_respondsToMethod((Class)self, aSelector);
}

- (BOOL)respondsTo:(SEL)aSelector 
{
	<span class="enscript-keyword">return</span> class_respondsToMethod(<span class="enscript-type">isa</span>, aSelector);
}

- copy 
{
	<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self copyFromZone: <span class="enscript-type">[</span>self zone<span class="enscript-type">]</span><span class="enscript-type">]</span>;
}

- copyFromZone:(void *)z
{
	<span class="enscript-keyword">return</span> (*_zoneCopy)(self, 0, z); 
}

- (IMP)methodFor:(SEL)aSelector 
{
	<span class="enscript-keyword">return</span> class_lookupMethod(<span class="enscript-type">isa</span>, aSelector);
}

+ (IMP)instanceMethodFor:(SEL)aSelector 
{
	<span class="enscript-keyword">return</span> class_lookupMethod(self, aSelector);
}

#<span class="enscript-keyword">if</span> defined(__alpha__)
#define MAX_RETSTRUCT_SIZE 256

typedef struct _foolGCC {
	<span class="enscript-type">char</span> c<span class="enscript-type">[</span>MAX_RETSTRUCT_SIZE<span class="enscript-type">]</span>;
} _variableStruct;

typedef _variableStruct (*callReturnsStruct)();

OBJC_EXPORT long sizeOfReturnedStruct(<span class="enscript-type">char</span> **);

long sizeOfType(<span class="enscript-type">char</span> **pp)
{
  <span class="enscript-type">char</span> *p = *pp;
  long stack_size = 0, n = 0;
  <span class="enscript-keyword">switch</span>(*p) {
  <span class="enscript-type">case</span> <span class="enscript-string">'c'</span>:
  <span class="enscript-type">case</span> <span class="enscript-string">'C'</span>:
    stack_size += sizeof(<span class="enscript-type">char</span>); // Alignment ?
    <span class="enscript-keyword">break</span>;
  <span class="enscript-type">case</span> <span class="enscript-string">'s'</span>:
  <span class="enscript-type">case</span> <span class="enscript-string">'S'</span>:
    stack_size += sizeof(short);// Alignment ?
    <span class="enscript-keyword">break</span>;
  <span class="enscript-type">case</span> <span class="enscript-string">'i'</span>:
  <span class="enscript-type">case</span> <span class="enscript-string">'I'</span>:
  <span class="enscript-type">case</span> <span class="enscript-string">'!'</span>:
    stack_size += sizeof(int);
    <span class="enscript-keyword">break</span>;
  <span class="enscript-type">case</span> <span class="enscript-string">'l'</span>:
  <span class="enscript-type">case</span> <span class="enscript-string">'L'</span>:
    stack_size += sizeof(long int);
    <span class="enscript-keyword">break</span>;
  <span class="enscript-type">case</span> <span class="enscript-string">'f'</span>:
    stack_size += sizeof(float);
    <span class="enscript-keyword">break</span>;
  <span class="enscript-type">case</span> <span class="enscript-string">'d'</span>:
    stack_size += sizeof(<span class="enscript-type">double</span>);
    <span class="enscript-keyword">break</span>;
  <span class="enscript-type">case</span> <span class="enscript-string">'*'</span>:
  <span class="enscript-type">case</span> <span class="enscript-string">':'</span>:
  <span class="enscript-type">case</span> <span class="enscript-string">'@'</span>:
  <span class="enscript-type">case</span> <span class="enscript-string">'%'</span>:
    stack_size += sizeof(<span class="enscript-type">char</span>*);
    <span class="enscript-keyword">break</span>;
  <span class="enscript-type">case</span> <span class="enscript-string">'{'</span>:
    stack_size += sizeOfReturnedStruct(&amp;p);
    <span class="enscript-keyword">while</span>(*p!=<span class="enscript-string">'}'</span>) p++;
    <span class="enscript-keyword">break</span>;
  <span class="enscript-type">case</span> <span class="enscript-string">'['</span>:
    p++;
    <span class="enscript-keyword">while</span>(isdigit(*p))
      n = 10 * n + (*p++ - <span class="enscript-string">'0'</span>);
    stack_size += (n * sizeOfType(&amp;p));
    <span class="enscript-keyword">break</span>;
  default:
    <span class="enscript-keyword">break</span>;
  }
  *pp = p;
  <span class="enscript-keyword">return</span> stack_size;
}

long
sizeOfReturnedStruct(<span class="enscript-type">char</span> **pp)
{
  <span class="enscript-type">char</span> *p = *pp;
  long stack_size = 0, n = 0;
  <span class="enscript-keyword">while</span>(p!=NULL &amp;&amp; *++p!=<span class="enscript-string">'='</span>) ; // skip the struct name
  <span class="enscript-keyword">while</span>(p!=NULL &amp;&amp; *++p!=<span class="enscript-string">'}'</span>)
    stack_size += sizeOfType(&amp;p);
  <span class="enscript-keyword">return</span> stack_size + 8;	// Add 8 as a <span class="enscript-string">'forfait value'</span>
  				// to take alignment into account
}

- perform:(SEL)aSelector 
{
  <span class="enscript-type">char</span> *p;
  long stack_size;
  _variableStruct *dummyRetVal;
  Method	method;

  <span class="enscript-keyword">if</span> (aSelector) {
    method = class_getInstanceMethod((Class)self-&gt;<span class="enscript-type">isa</span>,
				     aSelector);
    <span class="enscript-keyword">if</span>(method==NULL)
      method = class_getClassMethod((Class)self-&gt;<span class="enscript-type">isa</span>,
				    aSelector);
    <span class="enscript-keyword">if</span>(method!=NULL) {
      p = &amp;method-&gt;method_types<span class="enscript-type">[</span>0<span class="enscript-type">]</span>;
      <span class="enscript-keyword">if</span>(*p==<span class="enscript-string">'{'</span>) {
	// Method returns a structure
	stack_size = sizeOfReturnedStruct(&amp;p);
	<span class="enscript-keyword">if</span>(stack_size&lt;MAX_RETSTRUCT_SIZE)
	  {
	    //
	    // The MAX_RETSTRUCT_SIZE value allow us to support methods that
	    // <span class="enscript-keyword">return</span> structures whose <span class="enscript-type">size</span> is <span class="enscript-type">not</span> grater than
	    // MAX_RETSTRUCT_SIZE.
	    // This is because the compiler allocates space on the stack
	    // <span class="enscript-keyword">for</span> the <span class="enscript-type">size</span> of the <span class="enscript-keyword">return</span> structure, <span class="enscript-type">and</span> when the method
	    // returns, the structure is copied on the space allocated
	    // on the stack: <span class="enscript-keyword">if</span> the structure is greater than the space
	    // allocated<span class="enscript-keyword">...</span> bang! (the stack is gone:-)
	    //
	    ((callReturnsStruct)objc_msgSend)(self, aSelector);
	  }
	<span class="enscript-keyword">else</span>
	  {
	    dummyRetVal  = (_variableStruct*) malloc(stack_size);

	    // Following asm code is equivalent to:
	    // *dummyRetVal=((callReturnsStruct)objc_msgSend)(self,aSelector);
#<span class="enscript-keyword">if</span> 0
	    asm(&quot;ldq $16,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (dummyRetVal):);
</span>	    asm(&quot;ldq $17,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (self):);
</span>	    asm(&quot;ldq $18,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (aSelector):);
</span>	    asm(&quot;bis $31,1,$25&quot;);
	    asm(&quot;lda $27,objc_msgSend&quot;);
	    asm(&quot;jsr $26,($27),objc_msgSend&quot;);
	    asm(&quot;ldgp $29,0($26)&quot;);
#<span class="enscript-keyword">else</span>
*dummyRetVal=((callReturnsStruct)objc_msgSend)(self,aSelector);
#endif
	    free(dummyRetVal);
	  }
	// When the method <span class="enscript-keyword">return</span> a structure, we cannot <span class="enscript-keyword">return</span> it here
	// becuse we<span class="enscript-keyword">'</span>re <span class="enscript-type">not</span> called in the right way, so we must <span class="enscript-keyword">return</span>
	// something <span class="enscript-keyword">else</span>: wether it is self <span class="enscript-type">or</span> NULL is a matter of taste.
	<span class="enscript-keyword">return</span> (id)NULL;
      }
    }
    // We fall back here either because the method doesn<span class="enscript-keyword">'</span>t <span class="enscript-keyword">return</span>
    // a structure, <span class="enscript-type">or</span> because method is NULL: in this latter
    // <span class="enscript-type">case</span> the call to msgSend will <span class="enscript-type">try</span> to forward the message.
    <span class="enscript-keyword">return</span> objc_msgSend(self, aSelector);
  }

  // We fallback here only when aSelector is NULL
  <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self <span class="enscript-keyword">error</span>:_errBadSel, SELNAME(_cmd), aSelector<span class="enscript-type">]</span>;
}

- perform:(SEL)aSelector with:anObject 
{
  <span class="enscript-type">char</span> *p;
  long stack_size;
  _variableStruct *dummyRetVal;
  Method	method;

  <span class="enscript-keyword">if</span> (aSelector) {
    method = class_getInstanceMethod((Class)self-&gt;<span class="enscript-type">isa</span>,
				     aSelector);
    <span class="enscript-keyword">if</span>(method==NULL)
      method = class_getClassMethod((Class)self-&gt;<span class="enscript-type">isa</span>,
				    aSelector);
    <span class="enscript-keyword">if</span>(method!=NULL) {
      p = &amp;method-&gt;method_types<span class="enscript-type">[</span>0<span class="enscript-type">]</span>;
      <span class="enscript-keyword">if</span>(*p==<span class="enscript-string">'{'</span>) {
	// Method returns a structure
	stack_size = sizeOfReturnedStruct(&amp;p);
	<span class="enscript-keyword">if</span>(stack_size&lt;MAX_RETSTRUCT_SIZE)
	  {
	    //
	    // The MAX_RETSTRUCT_SIZE value allow us to support methods that
	    // <span class="enscript-keyword">return</span> structures whose <span class="enscript-type">size</span> is <span class="enscript-type">not</span> grater than
	    // MAX_RETSTRUCT_SIZE.
	    // This is because the compiler allocates space on the stack
	    // <span class="enscript-keyword">for</span> the <span class="enscript-type">size</span> of the <span class="enscript-keyword">return</span> structure, <span class="enscript-type">and</span> when the method
	    // returns, the structure is copied on the space allocated
	    // on the stack: <span class="enscript-keyword">if</span> the structure is greater than the space
	    // allocated<span class="enscript-keyword">...</span> bang! (the stack is gone:-)
	    //
	    ((callReturnsStruct)objc_msgSend)(self, aSelector, anObject);
	  }
	<span class="enscript-keyword">else</span>
	  {
	    dummyRetVal  = (_variableStruct*) malloc(stack_size);

	    // Following asm code is equivalent to:
	    // *dummyRetVal=((callReturnsStruct)objc_msgSend)(self,aSelector,anObject);
#<span class="enscript-keyword">if</span> 0
	    asm(&quot;ldq $16,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (dummyRetVal):);
</span>	    asm(&quot;ldq $17,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (self):);
</span>	    asm(&quot;ldq $18,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (aSelector):);
</span>	    asm(&quot;ldq $19,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (anObject):);
</span>	    asm(&quot;bis $31,1,$25&quot;);
	    asm(&quot;lda $27,objc_msgSend&quot;);
	    asm(&quot;jsr $26,($27),objc_msgSend&quot;);
	    asm(&quot;ldgp $29,0($26)&quot;);
#<span class="enscript-keyword">else</span>
 *dummyRetVal=((callReturnsStruct)objc_msgSend)(self,aSelector,anObject);
#endif
	    free(dummyRetVal);
	  }
	// When the method <span class="enscript-keyword">return</span> a structure, we cannot <span class="enscript-keyword">return</span> it here
	// becuse we<span class="enscript-keyword">'</span>re <span class="enscript-type">not</span> called in the right way, so we must <span class="enscript-keyword">return</span>
	// something <span class="enscript-keyword">else</span>: wether it is self <span class="enscript-type">or</span> NULL is a matter of taste.
	<span class="enscript-keyword">return</span> (id)NULL;
      }
    }
    // We fall back here either because the method doesn<span class="enscript-keyword">'</span>t <span class="enscript-keyword">return</span>
    // a structure, <span class="enscript-type">or</span> because method is NULL: in this latter
    // <span class="enscript-type">case</span> the call to msgSend will <span class="enscript-type">try</span> to forward the message.
    <span class="enscript-keyword">return</span> objc_msgSend(self, aSelector, anObject);
  }

  // We fallback here only when aSelector is NULL
  <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self <span class="enscript-keyword">error</span>:_errBadSel, SELNAME(_cmd), aSelector<span class="enscript-type">]</span>;
}

- perform:(SEL)aSelector with:obj1 with:obj2 
{
  <span class="enscript-type">char</span> *p;
  long stack_size;
  _variableStruct *dummyRetVal;
  Method	method;

  <span class="enscript-keyword">if</span> (aSelector) {
    method = class_getInstanceMethod((Class)self-&gt;<span class="enscript-type">isa</span>,
				     aSelector);
    <span class="enscript-keyword">if</span>(method==NULL)
      method = class_getClassMethod((Class)self-&gt;<span class="enscript-type">isa</span>,
				    aSelector);
    <span class="enscript-keyword">if</span>(method!=NULL) {
      p = &amp;method-&gt;method_types<span class="enscript-type">[</span>0<span class="enscript-type">]</span>;
      <span class="enscript-keyword">if</span>(*p==<span class="enscript-string">'{'</span>) {
	// Method returns a structure
	stack_size = sizeOfReturnedStruct(&amp;p);
	<span class="enscript-keyword">if</span>(stack_size&lt;MAX_RETSTRUCT_SIZE)
	  {
	    //
	    // The MAX_RETSTRUCT_SIZE value allow us to support methods that
	    // <span class="enscript-keyword">return</span> structures whose <span class="enscript-type">size</span> is <span class="enscript-type">not</span> grater than
	    // MAX_RETSTRUCT_SIZE.
	    // This is because the compiler allocates space on the stack
	    // <span class="enscript-keyword">for</span> the <span class="enscript-type">size</span> of the <span class="enscript-keyword">return</span> structure, <span class="enscript-type">and</span> when the method
	    // returns, the structure is copied on the space allocated
	    // on the stack: <span class="enscript-keyword">if</span> the structure is greater than the space
	    // allocated<span class="enscript-keyword">...</span> bang! (the stack is gone:-)
	    //
	    ((callReturnsStruct)objc_msgSend)(self, aSelector, obj1, obj2);
	  }
	<span class="enscript-keyword">else</span>
	  {
	    dummyRetVal  = (_variableStruct*) malloc(stack_size);

	    // Following asm code is equivalent to:
	    // *dummyRetVal=((callReturnsStruct)objc_msgSend)(self,aSelector,obj1,obj2);

#<span class="enscript-keyword">if</span> 0
	    asm(&quot;ldq $16,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (dummyRetVal):);
</span>	    asm(&quot;ldq $17,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (self):);
</span>	    asm(&quot;ldq $18,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (aSelector):);
</span>	    asm(&quot;ldq $19,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (obj1):);
</span>	    asm(&quot;ldq $20,<span class="enscript-comment">%0&quot;:&quot;=g&quot; (obj2):);
</span>	    asm(&quot;bis $31,1,$25&quot;);
	    asm(&quot;lda $27,objc_msgSend&quot;);
	    asm(&quot;jsr $26,($27),objc_msgSend&quot;);
	    asm(&quot;ldgp $29,0($26)&quot;);
#<span class="enscript-keyword">else</span>
*dummyRetVal=((callReturnsStruct)objc_msgSend)(self,aSelector,obj1,obj2);
#endif
	    free(dummyRetVal);
	  }
	// When the method <span class="enscript-keyword">return</span> a structure, we cannot <span class="enscript-keyword">return</span> it here
	// becuse we<span class="enscript-keyword">'</span>re <span class="enscript-type">not</span> called in the right way, so we must <span class="enscript-keyword">return</span>
	// something <span class="enscript-keyword">else</span>: wether it is self <span class="enscript-type">or</span> NULL is a matter of taste.
	<span class="enscript-keyword">return</span> (id)NULL;
      }
    }
    // We fall back here either because the method doesn<span class="enscript-keyword">'</span>t <span class="enscript-keyword">return</span>
    // a structure, <span class="enscript-type">or</span> because method is NULL: in this latter
    // <span class="enscript-type">case</span> the call to msgSend will <span class="enscript-type">try</span> to forward the message.
    <span class="enscript-keyword">return</span> objc_msgSend(self, aSelector, obj1, obj2);
  }

  // We fallback here only when aSelector is NULL
  <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self <span class="enscript-keyword">error</span>:_errBadSel, SELNAME(_cmd), aSelector<span class="enscript-type">]</span>;

}
#<span class="enscript-keyword">else</span>
- perform:(SEL)aSelector 
{ 
	<span class="enscript-keyword">if</span> (aSelector)
		<span class="enscript-keyword">return</span> objc_msgSend(self, aSelector); 
	<span class="enscript-keyword">else</span>
		<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self <span class="enscript-keyword">error</span>:_errBadSel, SELNAME(_cmd), aSelector<span class="enscript-type">]</span>;
}

- perform:(SEL)aSelector with:anObject 
{
	<span class="enscript-keyword">if</span> (aSelector)
		<span class="enscript-keyword">return</span> objc_msgSend(self, aSelector, anObject); 
	<span class="enscript-keyword">else</span>
		<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self <span class="enscript-keyword">error</span>:_errBadSel, SELNAME(_cmd), aSelector<span class="enscript-type">]</span>;
}

- perform:(SEL)aSelector with:obj1 with:obj2 
{
	<span class="enscript-keyword">if</span> (aSelector)
		<span class="enscript-keyword">return</span> objc_msgSend(self, aSelector, obj1, obj2); 
	<span class="enscript-keyword">else</span>
		<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self <span class="enscript-keyword">error</span>:_errBadSel, SELNAME(_cmd), aSelector<span class="enscript-type">]</span>;
}
#endif

- subclassResponsibility:(SEL)aSelector 
{
	<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self <span class="enscript-keyword">error</span>:_errShouldHaveImp, sel_getName(aSelector)<span class="enscript-type">]</span>;
}

- notImplemented:(SEL)aSelector
{
	<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self <span class="enscript-keyword">error</span>:_errLeftUndone, sel_getName(aSelector)<span class="enscript-type">]</span>;
}

- doesNotRecognize:(SEL)aMessage
{
	<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self <span class="enscript-keyword">error</span>:_errDoesntRecognize, 
		ISMETA (<span class="enscript-type">isa</span>) ? <span class="enscript-string">'+'</span> : <span class="enscript-string">'-'</span>, SELNAME(aMessage)<span class="enscript-type">]</span>;
}

- <span class="enscript-keyword">error</span>:(const <span class="enscript-type">char</span> *)aCStr, <span class="enscript-keyword">...</span> 
{
	va_list ap;
	va_start(ap,aCStr); 
	(*_error)(self, aCStr, ap); 
	_objc_error (self, aCStr, ap);	/* In <span class="enscript-type">case</span> (*_error)() returns. */
	va_end(ap);
        <span class="enscript-keyword">return</span> nil;
}

- (void) printForDebugger:(void *)stream
{
}

- write:(void *) stream 
{
	<span class="enscript-keyword">return</span> self;
}

- read:(void *) stream 
{
	<span class="enscript-keyword">return</span> self;
}

- forward: (SEL) sel : (marg_list) args 
{
    <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self doesNotRecognize: sel<span class="enscript-type">]</span>;
}

/* this method is <span class="enscript-type">not</span> part of the published API */

- (unsigned)methodArgSize:(SEL)sel 
{
    Method	method = class_getInstanceMethod((Class)<span class="enscript-type">isa</span>, sel);
    <span class="enscript-keyword">if</span> (! method) <span class="enscript-keyword">return</span> 0;
    <span class="enscript-keyword">return</span> method_getSizeOfArguments(method);
}

#<span class="enscript-keyword">if</span> defined(__alpha__)

typedef struct {
	unsigned long int i16;
	unsigned long int i17;
	unsigned long int i18;
	unsigned long int i19;
	unsigned long int i20;
	unsigned long int i21;
	unsigned long int i25;
	unsigned long int f16;
	unsigned long int f17;
	unsigned long int f18;
	unsigned long int f19;
	unsigned long int f20;
	unsigned long int f21;
	unsigned long int sp;
 } *_m_args_p;

- performv: (SEL) sel : (marg_list) args 
{
    <span class="enscript-type">char</span> *		p;
    long		stack_size;
    Method		method;
    unsigned long int	<span class="enscript-type">size</span>;
    <span class="enscript-type">char</span> 		scratchMem<span class="enscript-type">[</span>MAX_RETSTRUCT_SIZE<span class="enscript-type">]</span>;
    <span class="enscript-type">char</span> *		scratchMemP;

    // Messages to nil object always <span class="enscript-keyword">return</span> nil
    <span class="enscript-keyword">if</span> (! self) <span class="enscript-keyword">return</span> nil;

    // Got to have a selector
    <span class="enscript-keyword">if</span> (!sel)
        <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self <span class="enscript-keyword">error</span>:_errBadSel, SELNAME(_cmd), sel<span class="enscript-type">]</span>;

    // Handle a method <span class="enscript-type">which</span> returns a structure <span class="enscript-type">and</span>
    // has been called as such
    <span class="enscript-keyword">if</span> (((_m_args_p)args)-&gt;i25){
        // Calculate <span class="enscript-type">size</span> of the marg_list from the method<span class="enscript-keyword">'</span>s
        // signature.  This looks <span class="enscript-keyword">for</span> the method in self
        // <span class="enscript-type">and</span> its superclasses.
        <span class="enscript-type">size</span> = <span class="enscript-type">[</span>self methodArgSize: sel<span class="enscript-type">]</span>;

        // If neither self nor its superclasses implement
        // the method, forward the message because self
        // might know someone <span class="enscript-type">who</span> does.  This is a
        // &quot;chained&quot; forward<span class="enscript-keyword">...</span>
        <span class="enscript-keyword">if</span> (! <span class="enscript-type">size</span>) <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self forward: sel: args<span class="enscript-type">]</span>;

        // Message self with the specified selector <span class="enscript-type">and</span> arguments
        <span class="enscript-keyword">return</span> objc_msgSendv (self, sel, <span class="enscript-type">size</span>, args);
    }

    // Look <span class="enscript-keyword">for</span> instance method in self<span class="enscript-keyword">'</span>s <span class="enscript-type">class</span> <span class="enscript-type">and</span> superclasses
    method = class_getInstanceMethod((Class)self-&gt;<span class="enscript-type">isa</span>,sel);

    // Look <span class="enscript-keyword">for</span> <span class="enscript-type">class</span> method in self<span class="enscript-keyword">'</span>s <span class="enscript-type">class</span> <span class="enscript-type">and</span> superclass
    <span class="enscript-keyword">if</span>(method==NULL)
        method = class_getClassMethod((Class)self-&gt;<span class="enscript-type">isa</span>,sel);

    // If neither self nor its superclasses implement
    // the method, forward the message because self
    // might know someone <span class="enscript-type">who</span> does.  This is a
    // &quot;chained&quot; forward<span class="enscript-keyword">...</span>
    <span class="enscript-keyword">if</span>(method==NULL)
        <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self forward: sel: args<span class="enscript-type">]</span>;

    // Calculate <span class="enscript-type">size</span> of the marg_list from the method<span class="enscript-keyword">'</span>s
    // signature.
    <span class="enscript-type">size</span> = method_getSizeOfArguments(method);

    // Ready to send message <span class="enscript-type">now</span> <span class="enscript-keyword">if</span> the <span class="enscript-keyword">return</span> <span class="enscript-type">type</span>
    // is <span class="enscript-type">not</span> a structure
    p = &amp;method-&gt;method_types<span class="enscript-type">[</span>0<span class="enscript-type">]</span>;
    <span class="enscript-keyword">if</span>(*p!=<span class="enscript-string">'{'</span>)
        <span class="enscript-keyword">return</span> objc_msgSendv(self, sel, <span class="enscript-type">size</span>, args);

    // Method returns a structure
    stack_size = sizeOfReturnedStruct(&amp;p);
    <span class="enscript-keyword">if</span>(stack_size&gt;=MAX_RETSTRUCT_SIZE)
        scratchMemP = (<span class="enscript-type">char</span>*)malloc(stack_size);
    <span class="enscript-keyword">else</span>
        scratchMemP = &amp;scratchMem<span class="enscript-type">[</span>0<span class="enscript-type">]</span>;

    // Set i25 so objc_msgSendv will know that method returns a structure
    ((_m_args_p)args)-&gt;i25 = 1;
    
    // Set first param of method to be called to safe <span class="enscript-keyword">return</span> address
    ((_m_args_p)args)-&gt;i16 = (unsigned long int) scratchMemP;
    objc_msgSendv(self, sel, <span class="enscript-type">size</span>, args);

    <span class="enscript-keyword">if</span>(stack_size&gt;=MAX_RETSTRUCT_SIZE)
      free(scratchMemP);

    <span class="enscript-keyword">return</span> (id)NULL;
 }
#<span class="enscript-keyword">else</span>
- performv: (SEL) sel : (marg_list) args 
{
    unsigned	<span class="enscript-type">size</span>;
#<span class="enscript-keyword">if</span> hppa &amp;&amp; 0
    void *ret;
   
    // Save ret0 so methods that <span class="enscript-keyword">return</span> a struct might work.
    asm(&quot;copy <span class="enscript-comment">%%r28, %0&quot;: &quot;=r&quot;(ret): );
</span>#endif hppa

    // Messages to nil object always <span class="enscript-keyword">return</span> nil
    <span class="enscript-keyword">if</span> (! self) <span class="enscript-keyword">return</span> nil;

    // Calculate <span class="enscript-type">size</span> of the marg_list from the method<span class="enscript-keyword">'</span>s
    // signature.  This looks <span class="enscript-keyword">for</span> the method in self
    // <span class="enscript-type">and</span> its superclasses.
    <span class="enscript-type">size</span> = <span class="enscript-type">[</span>self methodArgSize: sel<span class="enscript-type">]</span>;

    // If neither self nor its superclasses implement
    // it, forward the message because self might know
    // someone <span class="enscript-type">who</span> does.  This is a &quot;chained&quot; forward<span class="enscript-keyword">...</span>
    <span class="enscript-keyword">if</span> (! <span class="enscript-type">size</span>) <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self forward: sel: args<span class="enscript-type">]</span>;

#<span class="enscript-keyword">if</span> hppa &amp;&amp; 0
    // Unfortunately, it looks like the compiler puts something <span class="enscript-keyword">else</span> in
    // r28 right after this instruction, so this is <span class="enscript-type">all</span> <span class="enscript-keyword">for</span> naught.
    asm(&quot;copy <span class="enscript-comment">%0, %%r28&quot;: : &quot;r&quot;(ret));
</span>#endif hppa

    // Message self with the specified selector <span class="enscript-type">and</span> arguments
    <span class="enscript-keyword">return</span> objc_msgSendv (self, sel, <span class="enscript-type">size</span>, args); 
}
#endif

/* Testing protocol conformance */

- (BOOL) conformsTo: (Protocol *)aProtocolObj
{
  <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>(id)<span class="enscript-type">isa</span> conformsTo:aProtocolObj<span class="enscript-type">]</span>;
}

+ (BOOL) conformsTo: (Protocol *)aProtocolObj
{
  struct objc_class * <span class="enscript-type">class</span>;

  <span class="enscript-keyword">for</span> (<span class="enscript-type">class</span> = self; <span class="enscript-type">class</span>; <span class="enscript-type">class</span> = <span class="enscript-type">class</span>-&gt;super_class)
    {
      <span class="enscript-keyword">if</span> (<span class="enscript-type">class</span>-&gt;<span class="enscript-type">isa</span>-&gt;<span class="enscript-type">version</span> &gt;= 3)
        {
	  struct objc_protocol_list *protocols = <span class="enscript-type">class</span>-&gt;protocols;

	  <span class="enscript-keyword">while</span> (protocols)
	    {
	      int <span class="enscript-type">i</span>;

	      <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; protocols-&gt;count; <span class="enscript-type">i</span>++)
		{
		  Protocol *p = protocols-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;
    
		  <span class="enscript-keyword">if</span> (<span class="enscript-type">[</span>p conformsTo:aProtocolObj<span class="enscript-type">]</span>)
		    <span class="enscript-keyword">return</span> YES;
		}

	      <span class="enscript-keyword">if</span> (<span class="enscript-type">class</span>-&gt;<span class="enscript-type">isa</span>-&gt;<span class="enscript-type">version</span> &lt;= 4)
	        <span class="enscript-keyword">break</span>;

	      protocols = protocols-&gt;next;
	    }
	}
    }
  <span class="enscript-keyword">return</span> NO;
}


/* Looking up information <span class="enscript-keyword">for</span> a method */

- (struct objc_method_description *) descriptionForMethod:(SEL)aSelector
{
  struct objc_class * cls;
  struct objc_method_description *m;

  /* Look in the protocols first. */
  <span class="enscript-keyword">for</span> (cls = <span class="enscript-type">isa</span>; cls; cls = cls-&gt;super_class)
    {
      <span class="enscript-keyword">if</span> (cls-&gt;<span class="enscript-type">isa</span>-&gt;<span class="enscript-type">version</span> &gt;= 3)
        {
	  struct objc_protocol_list *protocols = cls-&gt;protocols;
  
	  <span class="enscript-keyword">while</span> (protocols)
	    {
	      int <span class="enscript-type">i</span>;

	      <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; protocols-&gt;count; <span class="enscript-type">i</span>++)
		{
		  Protocol *p = protocols-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;

		  <span class="enscript-keyword">if</span> (ISMETA (cls))
		    m = <span class="enscript-type">[</span>p descriptionForClassMethod:aSelector<span class="enscript-type">]</span>;
		  <span class="enscript-keyword">else</span>
		    m = <span class="enscript-type">[</span>p descriptionForInstanceMethod:aSelector<span class="enscript-type">]</span>;

		  <span class="enscript-keyword">if</span> (m) {
		      <span class="enscript-keyword">return</span> m;
		  }
		}
  
	      <span class="enscript-keyword">if</span> (cls-&gt;<span class="enscript-type">isa</span>-&gt;<span class="enscript-type">version</span> &lt;= 4)
		<span class="enscript-keyword">break</span>;
  
	      protocols = protocols-&gt;next;
	    }
	}
    }

  /* Then <span class="enscript-type">try</span> the <span class="enscript-type">class</span> implementations. */
    <span class="enscript-keyword">for</span> (cls = <span class="enscript-type">isa</span>; cls; cls = cls-&gt;super_class) {
        void *iterator = 0;
	int <span class="enscript-type">i</span>;
        struct objc_method_list *mlist;
        <span class="enscript-keyword">while</span> ( (mlist = _class_inlinedNextMethodList( cls, &amp;iterator )) ) {
            <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; mlist-&gt;method_count; <span class="enscript-type">i</span>++)
                <span class="enscript-keyword">if</span> (mlist-&gt;method_list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>.method_name == aSelector) {
		    struct objc_method_description *m;
		    m = (struct objc_method_description *)&amp;mlist-&gt;method_list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;
                    <span class="enscript-keyword">return</span> m;
		}
        }
    }
 
  <span class="enscript-keyword">return</span> 0;
}

+ (struct objc_method_description *) descriptionForInstanceMethod:(SEL)aSelector
{
  struct objc_class * cls;

  /* Look in the protocols first. */
  <span class="enscript-keyword">for</span> (cls = self; cls; cls = cls-&gt;super_class)
    {
      <span class="enscript-keyword">if</span> (cls-&gt;<span class="enscript-type">isa</span>-&gt;<span class="enscript-type">version</span> &gt;= 3)
        {
	  struct objc_protocol_list *protocols = cls-&gt;protocols;
  
	  <span class="enscript-keyword">while</span> (protocols)
	    {
	      int <span class="enscript-type">i</span>;

	      <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; protocols-&gt;count; <span class="enscript-type">i</span>++)
		{
		  Protocol *p = protocols-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;
		  struct objc_method_description *m;

		  <span class="enscript-keyword">if</span> ((m = <span class="enscript-type">[</span>p descriptionForInstanceMethod:aSelector<span class="enscript-type">]</span>))
		    <span class="enscript-keyword">return</span> m;
		}
  
	      <span class="enscript-keyword">if</span> (cls-&gt;<span class="enscript-type">isa</span>-&gt;<span class="enscript-type">version</span> &lt;= 4)
		<span class="enscript-keyword">break</span>;
  
	      protocols = protocols-&gt;next;
	    }
	}
    }

  /* Then <span class="enscript-type">try</span> the <span class="enscript-type">class</span> implementations. */
    <span class="enscript-keyword">for</span> (cls = self; cls; cls = cls-&gt;super_class) {
        void *iterator = 0;
	int <span class="enscript-type">i</span>;
        struct objc_method_list *mlist;
        <span class="enscript-keyword">while</span> ( (mlist = _class_inlinedNextMethodList( cls, &amp;iterator )) ) {
            <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; mlist-&gt;method_count; <span class="enscript-type">i</span>++)
                <span class="enscript-keyword">if</span> (mlist-&gt;method_list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>.method_name == aSelector) {
		    struct objc_method_description *m;
		    m = (struct objc_method_description *)&amp;mlist-&gt;method_list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;
                    <span class="enscript-keyword">return</span> m;
		}
        }
    }

  <span class="enscript-keyword">return</span> 0;
}


/* Obsolete methods (<span class="enscript-keyword">for</span> binary compatibility only). */

+ superClass
{
	<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self superclass<span class="enscript-type">]</span>;
}

- superClass
{
	<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self superclass<span class="enscript-type">]</span>;
}

- (BOOL)isKindOfGivenName:(const <span class="enscript-type">char</span> *)aClassName
{
	<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self isKindOfClassNamed: aClassName<span class="enscript-type">]</span>;
}

- (BOOL)isMemberOfGivenName:(const <span class="enscript-type">char</span> *)aClassName 
{
	<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self isMemberOfClassNamed: aClassName<span class="enscript-type">]</span>;
}

- (struct objc_method_description *) methodDescFor:(SEL)aSelector
{
  <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self descriptionForMethod: aSelector<span class="enscript-type">]</span>;
}

+ (struct objc_method_description *) instanceMethodDescFor:(SEL)aSelector
{
  <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self descriptionForInstanceMethod: aSelector<span class="enscript-type">]</span>;
}

- findClass:(const <span class="enscript-type">char</span> *)aClassName
{
	<span class="enscript-keyword">return</span> (*_cvtToId)(aClassName);
}

- shouldNotImplement:(SEL)aSelector
{
	<span class="enscript-keyword">return</span> <span class="enscript-type">[</span>self <span class="enscript-keyword">error</span>:_errShouldNotImp, sel_getName(aSelector)<span class="enscript-type">]</span>;
}

@<span class="enscript-keyword">end</span>

static id _internal_object_copyFromZone(Object *anObject, unsigned nBytes, void *z) 
{
	id obj;
	register unsigned siz;

	<span class="enscript-keyword">if</span> (anObject == nil)
		<span class="enscript-keyword">return</span> nil;

	obj = (*_zoneAlloc)(anObject-&gt;<span class="enscript-type">isa</span>, nBytes, z);
	siz = ((struct objc_class *)anObject-&gt;<span class="enscript-type">isa</span>)-&gt;instance_size + nBytes;
	bcopy((const <span class="enscript-type">char</span>*)anObject, (<span class="enscript-type">char</span>*)obj, siz);
	<span class="enscript-keyword">return</span> obj;
}

static id _internal_object_copy(Object *anObject, unsigned nBytes) 
{
    void *z= malloc_zone_from_ptr(anObject);
    <span class="enscript-keyword">return</span> _internal_object_copyFromZone(anObject, 
					 nBytes,
					 z ? z : malloc_default_zone());
}

static id _internal_object_dispose(Object *anObject) 
{
	<span class="enscript-keyword">if</span> (anObject==nil) <span class="enscript-keyword">return</span> nil;
	anObject-&gt;<span class="enscript-type">isa</span> = _objc_getFreedObjectClass (); 
	free(anObject);
	<span class="enscript-keyword">return</span> nil;
}

static id _internal_object_reallocFromZone(Object *anObject, unsigned nBytes, void *z) 
{
	Object *newObject; 
	struct objc_class * tmp;

	<span class="enscript-keyword">if</span> (anObject == nil)
		__objc_error(nil, _errReAllocNil, 0);

	<span class="enscript-keyword">if</span> (anObject-&gt;<span class="enscript-type">isa</span> == _objc_getFreedObjectClass ())
		__objc_error(anObject, _errReAllocFreed, 0);

	<span class="enscript-keyword">if</span> (nBytes &lt; ((struct objc_class *)anObject-&gt;<span class="enscript-type">isa</span>)-&gt;instance_size)
		__objc_error(anObject, _errReAllocTooSmall, 
				object_getClassName(anObject), nBytes);

	// Make sure <span class="enscript-type">not</span> to modify space that has been declared free
	tmp = anObject-&gt;<span class="enscript-type">isa</span>; 
	anObject-&gt;<span class="enscript-type">isa</span> = _objc_getFreedObjectClass ();
	newObject = (Object*)malloc_zone_realloc(z, (void*)anObject, (size_t)nBytes);
	<span class="enscript-keyword">if</span> (newObject) {
		newObject-&gt;<span class="enscript-type">isa</span> = tmp;
		<span class="enscript-keyword">return</span> newObject;
	}
	<span class="enscript-keyword">else</span>
            {
		__objc_error(anObject, _errNoMem, 
				object_getClassName(anObject), nBytes);
                <span class="enscript-keyword">return</span> nil;
            }
}

static id _internal_object_realloc(Object *anObject, unsigned nBytes) 
{
    void *z= malloc_zone_from_ptr(anObject);
    <span class="enscript-keyword">return</span> _internal_object_reallocFromZone(anObject,
					    nBytes,
					    z ? z : malloc_default_zone());
}

/* Functional Interface to system primitives */

id object_copy(Object *anObject, unsigned nBytes) 
{
	<span class="enscript-keyword">return</span> (*_copy)(anObject, nBytes); 
}

id object_copyFromZone(Object *anObject, unsigned nBytes, void *z) 
{
	<span class="enscript-keyword">return</span> (*_zoneCopy)(anObject, nBytes, z); 
}

id object_dispose(Object *anObject) 
{
	<span class="enscript-keyword">return</span> (*_dealloc)(anObject); 
}

id object_realloc(Object *anObject, unsigned nBytes) 
{
	<span class="enscript-keyword">return</span> (*_realloc)(anObject, nBytes); 
}

id object_reallocFromZone(Object *anObject, unsigned nBytes, void *z) 
{
	<span class="enscript-keyword">return</span> (*_zoneRealloc)(anObject, nBytes, z); 
}

Ivar object_setInstanceVariable(id obj, const <span class="enscript-type">char</span> *name, void *value)
{
	Ivar ivar = 0;

	<span class="enscript-keyword">if</span> (obj &amp;&amp; name) {
		void **ivaridx;

		<span class="enscript-keyword">if</span> ((ivar = class_getInstanceVariable(((Object*)obj)-&gt;<span class="enscript-type">isa</span>, name))) {
		       ivaridx = (void **)((<span class="enscript-type">char</span> *)obj + ivar-&gt;ivar_offset);
		       *ivaridx = value;
		}
	}
	<span class="enscript-keyword">return</span> ivar;
}

Ivar object_getInstanceVariable(id obj, const <span class="enscript-type">char</span> *name, void **value)
{
	Ivar ivar = 0;

	<span class="enscript-keyword">if</span> (obj &amp;&amp; name) {
		void **ivaridx;

		<span class="enscript-keyword">if</span> ((ivar = class_getInstanceVariable(((Object*)obj)-&gt;<span class="enscript-type">isa</span>, name))) {
		       ivaridx = (void **)((<span class="enscript-type">char</span> *)obj + ivar-&gt;ivar_offset);
		       *value = *ivaridx;
		} <span class="enscript-keyword">else</span>
		       *value = 0;
	}
	<span class="enscript-keyword">return</span> ivar;
}

#<span class="enscript-keyword">if</span> defined(__hpux__)
id (*_objc_msgSend_v)(id, SEL, <span class="enscript-keyword">...</span>) = objc_msgSend;
#endif

id (*_copy)(id, unsigned) = _internal_object_copy;
id (*_realloc)(id, unsigned) = _internal_object_realloc;
id (*_dealloc)(id)  = _internal_object_dispose;
id (*_cvtToId)(const <span class="enscript-type">char</span> *)= objc_lookUpClass;
SEL (*_cvtToSel)(const <span class="enscript-type">char</span> *)= sel_getUid;
void (*_error)() = (void(*)())_objc_error;
id (*_zoneCopy)(id, unsigned, void *) = _internal_object_copyFromZone;
id (*_zoneRealloc)(id, unsigned, void *) = _internal_object_reallocFromZone;


</pre>
<hr />
</body></html>