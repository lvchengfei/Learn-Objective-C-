<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc-runtime.h</title>
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
<h1 style="margin:8px;" id="f1">objc-runtime.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
 *	objc-runtime.h
 *	Copyright 1988-1996, NeXT Software, Inc.
 */</span>

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">_OBJC_RUNTIME_H_</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_OBJC_RUNTIME_H_</span>

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">NeXT_PDO</span>
#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">stdarg</span>.<span class="enscript-variable-name">h</span>&gt;
#<span class="enscript-reference">endif</span>
#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">objc</span>/<span class="enscript-variable-name">objc</span>.<span class="enscript-variable-name">h</span>&gt;
#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">objc</span>/<span class="enscript-variable-name">objc</span>-<span class="enscript-variable-name">class</span>.<span class="enscript-variable-name">h</span>&gt;

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> objc_symtab *Symtab;

<span class="enscript-type">struct</span> objc_symtab {
	<span class="enscript-type">unsigned</span> <span class="enscript-type">long</span> 	sel_ref_cnt;
	SEL 		*refs;		
	<span class="enscript-type">unsigned</span> <span class="enscript-type">short</span> 	cls_def_cnt;
	<span class="enscript-type">unsigned</span> <span class="enscript-type">short</span> 	cat_def_cnt;
#<span class="enscript-reference">ifdef</span> <span class="enscript-variable-name">NeXT_PDO</span>
	arith_t        obj_defs;
	arith_t        proto_defs;
#<span class="enscript-reference">endif</span>
	<span class="enscript-type">void</span>  		*defs[1];	<span class="enscript-comment">/* variable size */</span>
};

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> objc_module *Module;

<span class="enscript-type">struct</span> objc_module {
	<span class="enscript-type">unsigned</span> <span class="enscript-type">long</span>	version;
	<span class="enscript-type">unsigned</span> <span class="enscript-type">long</span>	size;
	<span class="enscript-type">const</span> <span class="enscript-type">char</span>	*name;
	Symtab 		symtab;	
};

#<span class="enscript-reference">ifdef</span> <span class="enscript-variable-name">__cplusplus</span>
<span class="enscript-type">extern</span> <span class="enscript-string">&quot;Objective-C&quot;</span> {
#<span class="enscript-reference">endif</span>
<span class="enscript-type">struct</span> objc_super {
	id receiver;
	Class class;
};
#<span class="enscript-reference">ifdef</span> <span class="enscript-variable-name">__cplusplus</span>
}
#<span class="enscript-reference">endif</span>

<span class="enscript-comment">/* kernel operations */</span>

OBJC_EXPORT id <span class="enscript-function-name">objc_getClass</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *name);
OBJC_EXPORT id <span class="enscript-function-name">objc_getMetaClass</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *name);
OBJC_EXPORT id <span class="enscript-function-name">objc_msgSend</span>(id self, SEL op, ...);
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">WINNT</span>) || <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__cplusplus</span>)
<span class="enscript-comment">// The compiler on NT is broken when dealing with structure-returns.
</span><span class="enscript-comment">// Help out the compiler group by tweaking the prototype.
</span>OBJC_EXPORT id <span class="enscript-function-name">objc_msgSend_stret</span>(id self, SEL op, ...);
#<span class="enscript-reference">else</span>
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">objc_msgSend_stret</span>(<span class="enscript-type">void</span> * stretAddr, id self, SEL op, ...);
#<span class="enscript-reference">endif</span>
OBJC_EXPORT id <span class="enscript-function-name">objc_msgSendSuper</span>(<span class="enscript-type">struct</span> objc_super *super, SEL op, ...);
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">WINNT</span>) || <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__cplusplus</span>)
<span class="enscript-comment">// The compiler on NT is broken when dealing with structure-returns.
</span><span class="enscript-comment">// Help out the compiler group by tweaking the prototype.
</span>OBJC_EXPORT id <span class="enscript-function-name">objc_msgSendSuper_stret</span>(<span class="enscript-type">struct</span> objc_super *super, SEL op, ...);
#<span class="enscript-reference">else</span>
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">objc_msgSendSuper_stret</span>(<span class="enscript-type">void</span> * stretAddr, <span class="enscript-type">struct</span> objc_super *super, SEL op, ...);
#<span class="enscript-reference">endif</span>

<span class="enscript-comment">/* forwarding operations */</span>

OBJC_EXPORT id <span class="enscript-function-name">objc_msgSendv</span>(id self, SEL op, <span class="enscript-type">unsigned</span> arg_size, marg_list arg_frame);
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">objc_msgSendv_stret</span>(<span class="enscript-type">void</span> * stretAddr, id self, SEL op, <span class="enscript-type">unsigned</span> arg_size, marg_list arg_frame);

<span class="enscript-comment">/* 
    getting all the classes in the application...
    
    int objc_getClassList(buffer, bufferLen)
	classes is an array of Class values (which are pointers)
		which will be filled by the function; if this
		argument is NULL, no copying is done, only the
		return value is returned
	bufferLen is the number of Class values the given buffer
		can hold; if the buffer is not large enough to
		hold all the classes, the buffer is filled to
		the indicated capacity with some arbitrary subset
		of the known classes, which could be different
		from call to call
	returns the number of classes, which is the number put
		in the buffer if the buffer was large enough,
		or the length the buffer should have been

    int numClasses = 0, newNumClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    while (numClasses &lt; newNumClasses) {
        numClasses = newNumClasses;
        classes = realloc(classes, sizeof(Class) * numClasses);
        newNumClasses = objc_getClassList(classes, numClasses);
    }
    // now, can use the classes list; if NULL, there are no classes
    free(classes);

*/</span>
OBJC_EXPORT <span class="enscript-type">int</span> <span class="enscript-function-name">objc_getClassList</span>(Class *buffer, <span class="enscript-type">int</span> bufferLen);

#<span class="enscript-reference">define</span> <span class="enscript-variable-name">OBSOLETE_OBJC_GETCLASSES</span> 1
#<span class="enscript-reference">if</span> <span class="enscript-variable-name">OBSOLETE_OBJC_GETCLASSES</span>
OBJC_EXPORT <span class="enscript-type">void</span> *<span class="enscript-function-name">objc_getClasses</span>(<span class="enscript-type">void</span>);
#<span class="enscript-reference">endif</span>

OBJC_EXPORT id <span class="enscript-function-name">objc_lookUpClass</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *name);
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">objc_addClass</span>(Class myClass);

<span class="enscript-comment">/* customizing the error handling for objc_getClass/objc_getMetaClass */</span>

OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">objc_setClassHandler</span>(<span class="enscript-type">int</span> (*)(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *));

<span class="enscript-comment">/* Making the Objective-C runtime thread safe. */</span>
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">objc_setMultithreaded</span> (BOOL flag);

<span class="enscript-comment">/* overriding the default object allocation and error handling routines */</span>

OBJC_EXPORT <span class="enscript-function-name">id</span>	(*_alloc)(Class, <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span>);
OBJC_EXPORT <span class="enscript-function-name">id</span>	(*_copy)(id, <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span>);
OBJC_EXPORT <span class="enscript-function-name">id</span>	(*_realloc)(id, <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span>);
OBJC_EXPORT <span class="enscript-function-name">id</span>	(*_dealloc)(id);
OBJC_EXPORT <span class="enscript-function-name">id</span>	(*_zoneAlloc)(Class, <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span>, <span class="enscript-type">void</span> *);
OBJC_EXPORT <span class="enscript-function-name">id</span>	(*_zoneRealloc)(id, <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span>, <span class="enscript-type">void</span> *);
OBJC_EXPORT <span class="enscript-function-name">id</span>	(*_zoneCopy)(id, <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span>, <span class="enscript-type">void</span> *);

#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NeXT_PDO</span>)
    OBJC_EXPORT <span class="enscript-type">void</span>   (*_error)();
#<span class="enscript-reference">else</span>
    OBJC_EXPORT <span class="enscript-type">void</span>	(*_error)(id, <span class="enscript-type">const</span> <span class="enscript-type">char</span> *, va_list);
#<span class="enscript-reference">endif</span>

#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">WIN32</span>)
<span class="enscript-comment">/* This seems like a strange place to put this, but there's really
   no very appropriate place! */</span>
OBJC_EXPORT <span class="enscript-type">const</span> <span class="enscript-type">char</span>* <span class="enscript-function-name">NSRootDirectory</span>(<span class="enscript-type">void</span>);
#<span class="enscript-reference">endif</span> 

#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* _OBJC_RUNTIME_H_ */</span>
</pre>
<hr />
</body></html>