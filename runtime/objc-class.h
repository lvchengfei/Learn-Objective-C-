<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc-class.h</title>
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
<h1 style="margin:8px;" id="f1">objc-class.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
 *	objc-class.h
 *	Copyright 1988-1996, NeXT Software, Inc.
 */</span>

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">_OBJC_CLASS_H_</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_OBJC_CLASS_H_</span>

#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">objc</span>/<span class="enscript-variable-name">objc</span>.<span class="enscript-variable-name">h</span>&gt;
<span class="enscript-comment">/* 
 *	Class Template
 */</span>
<span class="enscript-type">struct</span> objc_class {			
	<span class="enscript-type">struct</span> objc_class *isa;	
	<span class="enscript-type">struct</span> objc_class *super_class;	
	<span class="enscript-type">const</span> <span class="enscript-type">char</span> *name;		
	<span class="enscript-type">long</span> version;
	<span class="enscript-type">long</span> info;
	<span class="enscript-type">long</span> instance_size;
	<span class="enscript-type">struct</span> objc_ivar_list *ivars;

#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">Release3CompatibilityBuild</span>)
	<span class="enscript-type">struct</span> objc_method_list *methods;
#<span class="enscript-reference">else</span>
	<span class="enscript-type">struct</span> objc_method_list **methodLists;
#<span class="enscript-reference">endif</span>

	<span class="enscript-type">struct</span> objc_cache *cache;
 	<span class="enscript-type">struct</span> objc_protocol_list *protocols;
};
#<span class="enscript-reference">define</span> <span class="enscript-function-name">CLS_GETINFO</span>(cls,infomask)	((cls)-&gt;info &amp; infomask)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">CLS_SETINFO</span>(cls,infomask)	((cls)-&gt;info |= infomask)

#<span class="enscript-reference">define</span> <span class="enscript-variable-name">CLS_CLASS</span>		0x1L
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">CLS_META</span>		0x2L
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">CLS_INITIALIZED</span>		0x4L
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">CLS_POSING</span>		0x8L
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">CLS_MAPPED</span>		0x10L
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">CLS_FLUSH_CACHE</span>		0x20L
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">CLS_GROW_CACHE</span>		0x40L
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">CLS_METHOD_ARRAY</span>        0x100L
<span class="enscript-comment">/* 
 *	Category Template
 */</span>
<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> objc_category *Category;

<span class="enscript-type">struct</span> objc_category {
	<span class="enscript-type">char</span> *category_name;
	<span class="enscript-type">char</span> *class_name;
	<span class="enscript-type">struct</span> objc_method_list *instance_methods;
	<span class="enscript-type">struct</span> objc_method_list *class_methods;
 	<span class="enscript-type">struct</span> objc_protocol_list *protocols;
};
<span class="enscript-comment">/* 
 *	Instance Variable Template
 */</span>
<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> objc_ivar *Ivar;

<span class="enscript-type">struct</span> objc_ivar_list {
	<span class="enscript-type">int</span> ivar_count;
#<span class="enscript-reference">ifdef</span> <span class="enscript-variable-name">__alpha__</span>
	<span class="enscript-type">int</span> space;
#<span class="enscript-reference">endif</span>
	<span class="enscript-type">struct</span> objc_ivar {
		<span class="enscript-type">char</span> *ivar_name;
		<span class="enscript-type">char</span> *ivar_type;
		<span class="enscript-type">int</span> ivar_offset;
#<span class="enscript-reference">ifdef</span> <span class="enscript-variable-name">__alpha__</span>
		<span class="enscript-type">int</span> space;
#<span class="enscript-reference">endif</span>
	} ivar_list[1];			<span class="enscript-comment">/* variable length structure */</span>
};

OBJC_EXPORT Ivar <span class="enscript-function-name">object_setInstanceVariable</span>(id, <span class="enscript-type">const</span> <span class="enscript-type">char</span> *name, <span class="enscript-type">void</span> *);
OBJC_EXPORT Ivar <span class="enscript-function-name">object_getInstanceVariable</span>(id, <span class="enscript-type">const</span> <span class="enscript-type">char</span> *name, <span class="enscript-type">void</span> **);

<span class="enscript-comment">/* 
 *	Method Template
 */</span>
<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> objc_method *Method;

<span class="enscript-type">struct</span> objc_method_list {
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">Release3CompatibilityBuild</span>)
        <span class="enscript-type">struct</span> objc_method_list *method_next;
#<span class="enscript-reference">else</span>
	<span class="enscript-type">struct</span> objc_method_list *obsolete;
#<span class="enscript-reference">endif</span>

	<span class="enscript-type">int</span> method_count;
#<span class="enscript-reference">ifdef</span> <span class="enscript-variable-name">__alpha__</span>
	<span class="enscript-type">int</span> space;
#<span class="enscript-reference">endif</span>
	<span class="enscript-type">struct</span> objc_method {
		SEL method_name;
		<span class="enscript-type">char</span> *method_types;
                IMP method_imp;
	} method_list[1];		<span class="enscript-comment">/* variable length structure */</span>
};

<span class="enscript-comment">/* Protocol support */</span>

@class Protocol;

<span class="enscript-type">struct</span> objc_protocol_list {
	<span class="enscript-type">struct</span> objc_protocol_list *next;
	<span class="enscript-type">int</span> count;
	Protocol *list[1];
};

<span class="enscript-comment">/* Definitions of filer types */</span>

#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_ID</span>		<span class="enscript-string">'@'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_CLASS</span>	<span class="enscript-string">'#'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_SEL</span>		<span class="enscript-string">':'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_CHR</span>		<span class="enscript-string">'c'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_UCHR</span>		<span class="enscript-string">'C'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_SHT</span>		<span class="enscript-string">'s'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_USHT</span>		<span class="enscript-string">'S'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_INT</span>		<span class="enscript-string">'i'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_UINT</span>		<span class="enscript-string">'I'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_LNG</span>		<span class="enscript-string">'l'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_ULNG</span>		<span class="enscript-string">'L'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_FLT</span>		<span class="enscript-string">'f'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_DBL</span>		<span class="enscript-string">'d'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_BFLD</span>		<span class="enscript-string">'b'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_VOID</span>		<span class="enscript-string">'v'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_UNDEF</span>	<span class="enscript-string">'?'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_PTR</span>		<span class="enscript-string">'^'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_CHARPTR</span>	<span class="enscript-string">'*'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_ARY_B</span>	<span class="enscript-string">'['</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_ARY_E</span>	<span class="enscript-string">']'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_UNION_B</span>	<span class="enscript-string">'('</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_UNION_E</span>	<span class="enscript-string">')'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_STRUCT_B</span>	<span class="enscript-string">'{'</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_C_STRUCT_E</span>	<span class="enscript-string">'}'</span>

<span class="enscript-comment">/* Structure for method cache - allocated/sized at runtime */</span>

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> objc_cache *	Cache;

#<span class="enscript-reference">define</span> <span class="enscript-function-name">CACHE_BUCKET_NAME</span>(B)  ((B)-&gt;method_name)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">CACHE_BUCKET_IMP</span>(B)   ((B)-&gt;method_imp)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">CACHE_BUCKET_VALID</span>(B) (B)
<span class="enscript-type">struct</span> objc_cache {
	<span class="enscript-type">unsigned</span> <span class="enscript-type">int</span> mask;            <span class="enscript-comment">/* total = mask + 1 */</span>
	<span class="enscript-type">unsigned</span> <span class="enscript-type">int</span> occupied;        
	Method buckets[1];
};

<span class="enscript-comment">/* operations */</span>
OBJC_EXPORT id <span class="enscript-function-name">class_createInstance</span>(Class, <span class="enscript-type">unsigned</span> idxIvars);
OBJC_EXPORT id <span class="enscript-function-name">class_createInstanceFromZone</span>(Class, <span class="enscript-type">unsigned</span> idxIvars, <span class="enscript-type">void</span> *z);

OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">class_setVersion</span>(Class, <span class="enscript-type">int</span>);
OBJC_EXPORT <span class="enscript-type">int</span> <span class="enscript-function-name">class_getVersion</span>(Class);

OBJC_EXPORT Ivar <span class="enscript-function-name">class_getInstanceVariable</span>(Class, <span class="enscript-type">const</span> <span class="enscript-type">char</span> *);
OBJC_EXPORT Method <span class="enscript-function-name">class_getInstanceMethod</span>(Class, SEL);
OBJC_EXPORT Method <span class="enscript-function-name">class_getClassMethod</span>(Class, SEL);

OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">class_addMethods</span>(Class, <span class="enscript-type">struct</span> objc_method_list *);
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">class_removeMethods</span>(Class, <span class="enscript-type">struct</span> objc_method_list *);

OBJC_EXPORT Class <span class="enscript-function-name">class_poseAs</span>(Class imposter, Class original);

OBJC_EXPORT <span class="enscript-type">unsigned</span> <span class="enscript-function-name">method_getNumberOfArguments</span>(Method);
OBJC_EXPORT <span class="enscript-type">unsigned</span> <span class="enscript-function-name">method_getSizeOfArguments</span>(Method);
OBJC_EXPORT <span class="enscript-type">unsigned</span> <span class="enscript-function-name">method_getArgumentInfo</span>(Method m, <span class="enscript-type">int</span> arg, <span class="enscript-type">const</span> <span class="enscript-type">char</span> **type, <span class="enscript-type">int</span> *offset);
OBJC_EXPORT <span class="enscript-type">const</span> <span class="enscript-type">char</span> * <span class="enscript-function-name">NSModulePathForClass</span> (Class aClass);

<span class="enscript-comment">// usage for nextMethodList
</span><span class="enscript-comment">//
</span><span class="enscript-comment">// void *iterator = 0;
</span><span class="enscript-comment">// struct objc_method_list *mlist;
</span><span class="enscript-comment">// while ( mlist = class_nextMethodList( cls, &amp;iterator ) )
</span><span class="enscript-comment">//    ;
</span>#<span class="enscript-reference">define</span> <span class="enscript-variable-name">OBJC_NEXT_METHOD_LIST</span> 1
OBJC_EXPORT <span class="enscript-type">struct</span> objc_method_list *<span class="enscript-function-name">class_nextMethodList</span>(Class, <span class="enscript-type">void</span> **);

<span class="enscript-type">typedef</span> <span class="enscript-type">void</span> *marg_list;

#<span class="enscript-reference">if</span> <span class="enscript-variable-name">hppa</span>

#<span class="enscript-reference">define</span> <span class="enscript-function-name">marg_malloc</span>(margs, method) \
	<span class="enscript-keyword">do</span> { \
		<span class="enscript-type">unsigned</span> <span class="enscript-type">int</span> _sz = (7 + method_getSizeOfArguments(method)) &amp; ~7; \
		<span class="enscript-type">char</span> *_ml = (<span class="enscript-type">char</span> *)malloc(_sz + <span class="enscript-keyword">sizeof</span>(marg_list)); \
		<span class="enscript-type">void</span>	**_z ; \
		margs = (marg_list *)(_ml + _sz); \
		_z = margs; \
		*_z = (marg_list)_ml; \
	} <span class="enscript-keyword">while</span> (0)

#<span class="enscript-reference">define</span> <span class="enscript-function-name">marg_free</span>(margs) \
	<span class="enscript-keyword">do</span> { \
		<span class="enscript-type">void</span>	**_z = margs; \
		free(*_z); \
	} <span class="enscript-keyword">while</span> (0)
	
#<span class="enscript-reference">define</span> <span class="enscript-function-name">marg_adjustedOffset</span>(method, offset) \
	( (!offset) ? -(<span class="enscript-keyword">sizeof</span>(id)) : offset)

#<span class="enscript-reference">else</span>

#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__ppc__</span>) || <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">ppc</span>)
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">marg_prearg_size</span>	128
#<span class="enscript-reference">else</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">marg_prearg_size</span>	0
#<span class="enscript-reference">endif</span>

#<span class="enscript-reference">define</span> <span class="enscript-function-name">marg_malloc</span>(margs, method) \
	<span class="enscript-keyword">do</span> { \
		margs = (marg_list *)malloc (marg_prearg_size + ((7 + method_getSizeOfArguments(method)) &amp; ~7)); \
	} <span class="enscript-keyword">while</span> (0)


#<span class="enscript-reference">define</span> <span class="enscript-function-name">marg_free</span>(margs) \
	<span class="enscript-keyword">do</span> { \
		free(margs); \
	} <span class="enscript-keyword">while</span> (0)
	
#<span class="enscript-reference">define</span> <span class="enscript-function-name">marg_adjustedOffset</span>(method, offset) \
	(marg_prearg_size + offset)

#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* hppa */</span>


#<span class="enscript-reference">define</span> <span class="enscript-function-name">marg_getRef</span>(margs, offset, type) \
	( (type *)((<span class="enscript-type">char</span> *)margs + marg_adjustedOffset(method,offset) ) )

#<span class="enscript-reference">define</span> <span class="enscript-function-name">marg_getValue</span>(margs, offset, type) \
	( *marg_getRef(margs, offset, type) )

#<span class="enscript-reference">define</span> <span class="enscript-function-name">marg_setValue</span>(margs, offset, type, value) \
	( marg_getValue(margs, offset, type) = (value) )

<span class="enscript-comment">/* Load categories and non-referenced classes from libraries. */</span>
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NeXT_PDO</span>)
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__hpux__</span>) || <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">hpux</span>)

#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REGISTER_SYMBOL</span>(NAME) asm(<span class="enscript-string">&quot;._&quot;</span> #NAME <span class="enscript-string">&quot;=0\n .globl ._&quot;</span> #NAME <span class="enscript-string">&quot;\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_SYMBOL</span>(NAME) asm(<span class="enscript-string">&quot;.SPACE $PRIVATE$\n\t.SUBSPA $DATA$\n\t.word ._&quot;</span> #NAME <span class="enscript-string">&quot;\n\t.SPACE $TEXT$\n\t.SUBSPA $CODE$\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REGISTER_CATEGORY</span>(NAME) asm(<span class="enscript-string">&quot;._&quot;</span> #NAME <span class="enscript-string">&quot;=0\n .globl ._&quot;</span> #NAME <span class="enscript-string">&quot;\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_CATEGORY</span>(NAME) asm(<span class="enscript-string">&quot;.SPACE $PRIVATE$\n\t.SUBSPA $DATA$\n\t.word ._&quot;</span> #NAME <span class="enscript-string">&quot;\n\t.SPACE $TEXT$\n\t.SUBSPA $CODE$\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_CLASS_CATEGORY</span>(CL, CAT) asm(<span class="enscript-string">&quot;.SPACE $PRIVATE$\n\t.SUBSPA $DATA$\n\t.word .objc_category_name_&quot;</span> #CL <span class="enscript-string">&quot;_&quot;</span> #CAT <span class="enscript-string">&quot;\n\t.SPACE $TEXT$\n\t.SUBSPA $CODE$\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_CLASS</span>(NAME) asm(<span class="enscript-string">&quot;.SPACE $PRIVATE$\n\t.SUBSPA $DATA$\n\t.word .objc_class_name_&quot;</span> #NAME <span class="enscript-string">&quot;\n\t.SPACE $TEXT$\n\t.SUBSPA $CODE$\n&quot;</span>)

#<span class="enscript-reference">elif</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__osf__</span>)

#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REGISTER_SYMBOL</span>(NAME) asm(<span class="enscript-string">&quot;.globl ._&quot;</span> #NAME <span class="enscript-string">&quot;\n\t.align 3\n._&quot;</span> #NAME <span class="enscript-string">&quot;:\n\t.quad 0\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_SYMBOL</span>(NAME) asm(<span class="enscript-string">&quot;.align 3\n\t.quad ._&quot;</span> #NAME <span class="enscript-string">&quot;\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REGISTER_CATEGORY</span>(NAME) asm(<span class="enscript-string">&quot;.globl ._&quot;</span> #NAME <span class="enscript-string">&quot;\n\t.align 3\n._&quot;</span> #NAME <span class="enscript-string">&quot;:\n\t.quad 0\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_CATEGORY</span>(NAME) asm(<span class="enscript-string">&quot;.align 3\n\t.quad ._&quot;</span> #NAME <span class="enscript-string">&quot;\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_CLASS_CATEGORY</span>(CL, CAT) asm(<span class="enscript-string">&quot;.align 3\n\t.quad .objc_category_name_&quot;</span> #CL <span class="enscript-string">&quot;_&quot;</span> #CAT <span class="enscript-string">&quot;\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_CLASS</span>(NAME) asm(<span class="enscript-string">&quot;.quad .objc_class_name_&quot;</span> #NAME <span class="enscript-string">&quot;\n&quot;</span>)

#<span class="enscript-reference">else</span>	<span class="enscript-comment">/* Solaris || SunOS */</span>

#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REGISTER_SYMBOL</span>(NAME) asm(<span class="enscript-string">&quot;._&quot;</span> #NAME <span class="enscript-string">&quot;=0\n .globl ._&quot;</span> #NAME <span class="enscript-string">&quot;\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_SYMBOL</span>(NAME) asm(<span class="enscript-string">&quot;.global ._&quot;</span> #NAME <span class="enscript-string">&quot;\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REGISTER_CATEGORY</span>(NAME) asm(<span class="enscript-string">&quot;._&quot;</span> #NAME <span class="enscript-string">&quot;=0\n .globl ._&quot;</span> #NAME <span class="enscript-string">&quot;\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_CATEGORY</span>(NAME) asm(<span class="enscript-string">&quot;.global ._&quot;</span> #NAME <span class="enscript-string">&quot;\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_CLASS_CATEGORY</span>(CL, CAT) asm(<span class="enscript-string">&quot;.global .objc_category_name_&quot;</span> #CL <span class="enscript-string">&quot;_&quot;</span> #CAT <span class="enscript-string">&quot;\n&quot;</span>)
#<span class="enscript-reference">define</span> <span class="enscript-function-name">OBJC_REFERENCE_CLASS</span>(NAME) asm(<span class="enscript-string">&quot;.global .objc_class_name_&quot;</span> #NAME <span class="enscript-string">&quot;\n&quot;</span>)

#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* __hpux__ || hpux */</span>
#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* NeXT_PDO */</span>

#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* _OBJC_CLASS_H_ */</span>
</pre>
<hr />
</body></html>