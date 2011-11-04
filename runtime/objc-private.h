<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc-private.h</title>
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
<h1 style="margin:8px;" id="f1">objc-private.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
 *	objc-private.h
 *	Copyright 1988-1996, NeXT Software, Inc.
 */</span>

#<span class="enscript-reference">if</span> !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">_OBJC_PRIVATE_H_</span>)
    #define _OBJC_PRIVATE_H_

    #import &lt;objc/objc-api.h&gt;	<span class="enscript-comment">// for OBJC_EXPORT
</span>
    OBJC_EXPORT <span class="enscript-type">void</span> checkUniqueness();

    #import <span class="enscript-string">&quot;objc-config.h&quot;</span>

    #<span class="enscript-keyword">if</span> defined(NeXT_PDO)
        #define LITERAL_STRING_OBJECTS
        #import &lt;mach/cthreads_private.h&gt;
        #<span class="enscript-keyword">if</span> defined(WIN32)
	    #import &lt;winnt-pdo.h&gt;
	    #import &lt;ntunix.h&gt;
	#<span class="enscript-keyword">else</span>
            #import &lt;pdo.h&gt;	<span class="enscript-comment">// for pdo_malloc and pdo_free defines
</span>            #import &lt;sys/time.h&gt;
        #endif
    #<span class="enscript-keyword">else</span>
        #import &lt;pthread.h&gt;
        #define	mutex_alloc()	(pthread_mutex_t*)calloc(1, <span class="enscript-keyword">sizeof</span>(pthread_mutex_t))
        #define	mutex_init(m)	pthread_mutex_init(m, NULL)
        #define	mutex_lock(m)	pthread_mutex_lock(m)
        #define	mutex_try_lock(m) (! pthread_mutex_trylock(m))
        #define	mutex_unlock(m)	pthread_mutex_unlock(m)
        #define	mutex_clear(m)
        #define	mutex_t		pthread_mutex_t*
        #define mutex		MUTEX_DEFINE_ERROR
        #import &lt;sys/time.h&gt;
    #endif

    #import &lt;stdlib.h&gt;
    #import &lt;stdarg.h&gt;
    #import &lt;stdio.h&gt;
    #import &lt;string.h&gt;
    #import &lt;ctype.h&gt;

    #import &lt;objc/objc-runtime.h&gt;

    <span class="enscript-comment">// This needs &lt;...&gt; -- malloc.h is not ours, really...
</span>    #import &lt;objc/malloc.h&gt;


<span class="enscript-comment">/* Opaque cookie used in _getObjc... routines.  File format independant.
 * This is used in place of the mach_header.  In fact, when compiling
 * for NEXTSTEP, this is really a (struct mach_header *).
 *
 * had been: typedef void *objc_header;
 */</span>
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NeXT_PDO</span>)
    <span class="enscript-type">typedef</span> <span class="enscript-type">void</span> headerType;
#<span class="enscript-reference">else</span> 
    #import &lt;mach-o/loader.h&gt;
    <span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> mach_header headerType;
#<span class="enscript-reference">endif</span> 

#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">objc</span>/<span class="enscript-variable-name">Protocol</span>.<span class="enscript-variable-name">h</span>&gt;

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> _ProtocolTemplate { @defs(Protocol) } ProtocolTemplate;
<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> _NXConstantStringTemplate {
    Class isa;
    <span class="enscript-type">void</span> *characters;
    <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span> _length;
} NXConstantStringTemplate;
   
#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NeXT_PDO</span>)
    #define OBJC_CONSTANT_STRING_PTR NXConstantStringTemplate**
    #define OBJC_CONSTANT_STRING_DEREF
    #define OBJC_PROTOCOL_PTR ProtocolTemplate**
    #define OBJC_PROTOCOL_DEREF -&gt; 
#<span class="enscript-reference">elif</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__MACH__</span>)
    #define OBJC_CONSTANT_STRING_PTR NXConstantStringTemplate*
    #define OBJC_CONSTANT_STRING_DEREF &amp;
    #define OBJC_PROTOCOL_PTR ProtocolTemplate*
    #define OBJC_PROTOCOL_DEREF .
#<span class="enscript-reference">endif</span>

<span class="enscript-comment">// both
</span>OBJC_EXPORT headerType **	_getObjcHeaders();
OBJC_EXPORT Module		_getObjcModules(headerType *head, <span class="enscript-type">int</span> *nmodules);
OBJC_EXPORT Class *		_getObjcClassRefs(headerType *head, <span class="enscript-type">int</span> *nclasses);
OBJC_EXPORT <span class="enscript-type">void</span> *		_getObjcHeaderData(headerType *head, <span class="enscript-type">unsigned</span> *size);
OBJC_EXPORT <span class="enscript-type">const</span> <span class="enscript-type">char</span> *	_getObjcHeaderName(headerType *head);

#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NeXT_PDO</span>) // <span class="enscript-variable-name">GENERIC_OBJ_FILE</span>
    OBJC_EXPORT ProtocolTemplate ** _getObjcProtocols(headerType *head, <span class="enscript-type">int</span> *nprotos);
    OBJC_EXPORT NXConstantStringTemplate **_getObjcStringObjects(headerType *head, <span class="enscript-type">int</span> *nstrs);
#<span class="enscript-reference">elif</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__MACH__</span>)
    OBJC_EXPORT ProtocolTemplate * _getObjcProtocols(headerType *head, <span class="enscript-type">int</span> *nprotos);
    OBJC_EXPORT NXConstantStringTemplate *_getObjcStringObjects(headerType *head, <span class="enscript-type">int</span> *nstrs);
    OBJC_EXPORT SEL *		_getObjcMessageRefs(headerType *head, <span class="enscript-type">int</span> *nmess);
#<span class="enscript-reference">endif</span> 

    #define END_OF_METHODS_LIST ((<span class="enscript-type">struct</span> objc_method_list*)-1)

    <span class="enscript-type">struct</span> header_info
    {
      <span class="enscript-type">const</span> headerType *	mhdr;
      Module				mod_ptr;
      <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span>			mod_count;
      <span class="enscript-type">unsigned</span> <span class="enscript-type">long</span>			image_slide;
      <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span>			objcSize;
    };
    <span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> header_info	header_info;
    OBJC_EXPORT header_info *_objc_headerVector (<span class="enscript-type">const</span> headerType * <span class="enscript-type">const</span> *machhdrs);
    OBJC_EXPORT <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span> _objc_headerCount (<span class="enscript-type">void</span>);
    OBJC_EXPORT <span class="enscript-type">void</span> _objc_addHeader (<span class="enscript-type">const</span> headerType *header, <span class="enscript-type">unsigned</span> <span class="enscript-type">long</span> vmaddr_slide);

    OBJC_EXPORT <span class="enscript-type">int</span> _objcModuleCount();
    OBJC_EXPORT <span class="enscript-type">const</span> <span class="enscript-type">char</span> *_objcModuleNameAtIndex(<span class="enscript-type">int</span> i);
    OBJC_EXPORT Class objc_getOrigClass (<span class="enscript-type">const</span> <span class="enscript-type">char</span> *name);

    <span class="enscript-type">extern</span> <span class="enscript-type">struct</span> objc_method_list **get_base_method_list(Class cls);


    OBJC_EXPORT <span class="enscript-type">const</span> <span class="enscript-type">char</span> *__S(_nameForHeader) (<span class="enscript-type">const</span> headerType*);

    <span class="enscript-comment">/* initialize */</span>
    OBJC_EXPORT <span class="enscript-type">void</span> _sel_resolve_conflicts(headerType * header, <span class="enscript-type">unsigned</span> <span class="enscript-type">long</span> slide);
    OBJC_EXPORT <span class="enscript-type">void</span> _class_install_relationships(Class, <span class="enscript-type">long</span>);
    OBJC_EXPORT <span class="enscript-type">void</span> _objc_add_category(Category, <span class="enscript-type">int</span>);
    OBJC_EXPORT <span class="enscript-type">void</span> *_objc_create_zone(<span class="enscript-type">void</span>);

    OBJC_EXPORT SEL sel_registerNameNoCopy(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *str);

    <span class="enscript-comment">/* selector fixup in method lists */</span>

    #define _OBJC_FIXED_UP ((<span class="enscript-type">void</span> *)1771)

    <span class="enscript-type">static</span> inline <span class="enscript-type">struct</span> objc_method_list *_objc_inlined_fixup_selectors_in_method_list(<span class="enscript-type">struct</span> objc_method_list *mlist)
    {
        <span class="enscript-type">unsigned</span> i, size;
        Method method;
        <span class="enscript-type">struct</span> objc_method_list *old_mlist; 
        
        <span class="enscript-keyword">if</span> ( ! mlist ) <span class="enscript-keyword">return</span> (<span class="enscript-type">struct</span> objc_method_list *)0;
        <span class="enscript-keyword">if</span> ( mlist-&gt;obsolete != _OBJC_FIXED_UP ) {
            old_mlist = mlist;
            size = <span class="enscript-keyword">sizeof</span>(<span class="enscript-type">struct</span> objc_method_list) - <span class="enscript-keyword">sizeof</span>(<span class="enscript-type">struct</span> objc_method) + old_mlist-&gt;method_count * <span class="enscript-keyword">sizeof</span>(<span class="enscript-type">struct</span> objc_method);
            mlist = malloc_zone_malloc(_objc_create_zone(), size);
            memmove(mlist, old_mlist, size);
            <span class="enscript-keyword">for</span> ( i = 0; i &lt; mlist-&gt;method_count; i += 1 ) {
                method = &amp;mlist-&gt;method_list[i];
                method-&gt;method_name =
                    sel_registerNameNoCopy((<span class="enscript-type">const</span> <span class="enscript-type">char</span> *)method-&gt;method_name);
            }
            mlist-&gt;obsolete = _OBJC_FIXED_UP;
        }
        <span class="enscript-keyword">return</span> mlist;
    }

    <span class="enscript-comment">/* method lookup */</span>
    <span class="enscript-comment">/* --  inline version of class_nextMethodList(Class, void **)  -- */</span>

    <span class="enscript-type">static</span> inline <span class="enscript-type">struct</span> objc_method_list *_class_inlinedNextMethodList(Class cls, <span class="enscript-type">void</span> **it)
    {
        <span class="enscript-type">struct</span> objc_method_list ***iterator;

        iterator = (<span class="enscript-type">struct</span> objc_method_list***)it;
        <span class="enscript-keyword">if</span> (*iterator == NULL) {
            *iterator = &amp;((((<span class="enscript-type">struct</span> objc_class *) cls)-&gt;methodLists)[0]);
        }
        <span class="enscript-keyword">else</span> (*iterator) += 1;
        <span class="enscript-comment">// Check for list end
</span>        <span class="enscript-keyword">if</span> ((**iterator == NULL) || (**iterator == END_OF_METHODS_LIST)) {
            *it = nil;
            <span class="enscript-keyword">return</span> NULL;
        }
        
        **iterator = _objc_inlined_fixup_selectors_in_method_list(**iterator);
        
        <span class="enscript-comment">// Return method list pointer
</span>        <span class="enscript-keyword">return</span> **iterator;
    }

    OBJC_EXPORT BOOL class_respondsToMethod(Class, SEL);
    OBJC_EXPORT IMP class_lookupMethod(Class, SEL);
    OBJC_EXPORT IMP class_lookupMethodInMethodList(<span class="enscript-type">struct</span> objc_method_list *mlist, SEL sel);
    OBJC_EXPORT IMP class_lookupNamedMethodInMethodList(<span class="enscript-type">struct</span> objc_method_list *mlist, <span class="enscript-type">const</span> <span class="enscript-type">char</span> *meth_name);
    OBJC_EXPORT <span class="enscript-type">void</span> _objc_insertMethods( <span class="enscript-type">struct</span> objc_method_list *mlist, <span class="enscript-type">struct</span> objc_method_list ***list );
    OBJC_EXPORT <span class="enscript-type">void</span> _objc_removeMethods( <span class="enscript-type">struct</span> objc_method_list *mlist, <span class="enscript-type">struct</span> objc_method_list ***list );

    <span class="enscript-comment">/* message dispatcher */</span>
    OBJC_EXPORT Cache _cache_create(Class);
    OBJC_EXPORT IMP _class_lookupMethodAndLoadCache(Class, SEL);
    OBJC_EXPORT id _objc_msgForward (id self, SEL sel, ...);

    <span class="enscript-comment">/* errors */</span>
    OBJC_EXPORT <span class="enscript-type">volatile</span> <span class="enscript-type">void</span> __S(_objc_fatal)(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *message);
    OBJC_EXPORT <span class="enscript-type">volatile</span> <span class="enscript-type">void</span> _objc_error(id, <span class="enscript-type">const</span> <span class="enscript-type">char</span> *, va_list);
    OBJC_EXPORT <span class="enscript-type">volatile</span> <span class="enscript-type">void</span> __objc_error(id, <span class="enscript-type">const</span> <span class="enscript-type">char</span> *, ...);
    OBJC_EXPORT <span class="enscript-type">void</span> _objc_inform(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *fmt, ...);
    OBJC_EXPORT <span class="enscript-type">void</span> _NXLogError(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *format, ...);

    <span class="enscript-comment">/* magic */</span>
    OBJC_EXPORT Class _objc_getFreedObjectClass (<span class="enscript-type">void</span>);
    OBJC_EXPORT <span class="enscript-type">const</span> <span class="enscript-type">struct</span> objc_cache emptyCache;
    OBJC_EXPORT <span class="enscript-type">void</span> _objc_flush_caches (Class cls);
    
    <span class="enscript-comment">/* locking */</span>
    #<span class="enscript-keyword">if</span> defined(NeXT_PDO)
        #<span class="enscript-keyword">if</span> defined(WIN32)
            #define MUTEX_TYPE <span class="enscript-type">long</span>
            #define OBJC_DECLARE_LOCK(MUTEX) MUTEX_TYPE MUTEX = 0L;
        #elif defined(sparc)
            #define MUTEX_TYPE <span class="enscript-type">long</span>
            #define OBJC_DECLARE_LOCK(MUTEX) MUTEX_TYPE MUTEX = 0L;
        #elif defined(__alpha__)
            #define MUTEX_TYPE <span class="enscript-type">long</span>
            #define OBJC_DECLARE_LOCK(MUTEX) MUTEX_TYPE MUTEX = 0L;
        #elif defined(__hpux__) || defined(hpux)
            <span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> { <span class="enscript-type">int</span> a; <span class="enscript-type">int</span> b; <span class="enscript-type">int</span> c; <span class="enscript-type">int</span> d; } __mutex_struct;
            #define MUTEX_TYPE __mutex_struct
            #define OBJC_DECLARE_LOCK(MUTEX) MUTEX_TYPE MUTEX = { 1, 1, 1, 1 };
        #<span class="enscript-keyword">else</span> <span class="enscript-comment">// unknown pdo platform
</span>            #define MUTEX_TYPE <span class="enscript-type">long</span>
            #define OBJC_DECLARE_LOCK(MUTEX) <span class="enscript-type">struct</span> mutex MUTEX = { 0 };
        #endif <span class="enscript-comment">// WIN32
</span>        OBJC_EXPORT MUTEX_TYPE classLock;
        OBJC_EXPORT MUTEX_TYPE messageLock;
    #<span class="enscript-keyword">else</span>
        #define MUTEX_TYPE pthread_mutex_t*
        #define OBJC_DECLARE_LOCK(MTX) pthread_mutex_t MTX = PTHREAD_MUTEX_INITIALIZER
        OBJC_EXPORT pthread_mutex_t classLock;
        OBJC_EXPORT pthread_mutex_t messageLock;
    #endif <span class="enscript-comment">// NeXT_PDO
</span>
    OBJC_EXPORT <span class="enscript-type">int</span> _objc_multithread_mask;

    <span class="enscript-comment">// _objc_msgNil is actually (unsigned dummy, id, SEL) for i386;
</span>    <span class="enscript-comment">// currently not implemented for any sparc or hppa platforms
</span>    OBJC_EXPORT <span class="enscript-type">void</span> (*_objc_msgNil)(id, SEL);

    <span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> {
       <span class="enscript-type">long</span> addressOffset;
       <span class="enscript-type">long</span> selectorOffset;
    } FixupEntry;

    <span class="enscript-type">static</span> inline <span class="enscript-type">int</span> selEqual( SEL s1, SEL s2 ) {
       OBJC_EXPORT <span class="enscript-type">int</span> rocketLaunchingDebug;
       <span class="enscript-keyword">if</span> ( rocketLaunchingDebug )
          checkUniqueness(s1, s2);
       <span class="enscript-keyword">return</span> (s1 == s2);
    }

        #<span class="enscript-keyword">if</span> defined(OBJC_COLLECTING_CACHE)
            #define OBJC_LOCK(MUTEX) 	mutex_lock (MUTEX)
            #define OBJC_UNLOCK(MUTEX)	mutex_unlock (MUTEX)
            #define OBJC_TRYLOCK(MUTEX)	mutex_try_lock (MUTEX)
        #elif defined(NeXT_PDO)
            #<span class="enscript-keyword">if</span> !defined(WIN32)
                <span class="enscript-comment">/* Where are these defined?  NT should probably be using them! */</span>
                OBJC_EXPORT <span class="enscript-type">void</span> _objc_private_lock(MUTEX_TYPE*);
                OBJC_EXPORT <span class="enscript-type">void</span> _objc_private_unlock(MUTEX_TYPE*);

                <span class="enscript-comment">/* I don't think this should be commented out for NT, should it? */</span>
                #define OBJC_LOCK(MUTEX)		\
                    <span class="enscript-keyword">do</span> {<span class="enscript-keyword">if</span> (!_objc_multithread_mask)	\
                    _objc_private_lock(MUTEX);} <span class="enscript-keyword">while</span>(0)
                #define OBJC_UNLOCK(MUTEX)		\
                    <span class="enscript-keyword">do</span> {<span class="enscript-keyword">if</span> (!_objc_multithread_mask)	\
                    _objc_private_unlock(MUTEX);} <span class="enscript-keyword">while</span>(0)
            #<span class="enscript-keyword">else</span>
                #define OBJC_LOCK(MUTEX)		\
                    <span class="enscript-keyword">do</span> {<span class="enscript-keyword">if</span> (!_objc_multithread_mask)	\
                    <span class="enscript-keyword">if</span>( *MUTEX == 0 ) *MUTEX = 1;} <span class="enscript-keyword">while</span>(0)
                #define OBJC_UNLOCK(MUTEX)		\
                    <span class="enscript-keyword">do</span> {<span class="enscript-keyword">if</span> (!_objc_multithread_mask)	\
                    *MUTEX = 0;} <span class="enscript-keyword">while</span>(0)
            #endif <span class="enscript-comment">// WIN32
</span>
        #<span class="enscript-keyword">else</span> <span class="enscript-comment">// not NeXT_PDO
</span>            #define OBJC_LOCK(MUTEX)			\
              <span class="enscript-keyword">do</span>					\
                {					\
                  <span class="enscript-keyword">if</span> (!_objc_multithread_mask)		\
            	mutex_lock (MUTEX);			\
                }					\
              <span class="enscript-keyword">while</span> (0)

            #define OBJC_UNLOCK(MUTEX)			\
              <span class="enscript-keyword">do</span>					\
                {					\
                  <span class="enscript-keyword">if</span> (!_objc_multithread_mask)		\
            	mutex_unlock (MUTEX);			\
                }					\
              <span class="enscript-keyword">while</span> (0)
        #endif <span class="enscript-comment">/* OBJC_COLLECTING_CACHE */</span>

#<span class="enscript-reference">if</span> !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">SEG_OBJC</span>)
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">SEG_OBJC</span>        <span class="enscript-string">&quot;__OBJC&quot;</span>        <span class="enscript-comment">/* objective-C runtime segment */</span>
#<span class="enscript-reference">endif</span>

#<span class="enscript-reference">if</span> <span class="enscript-reference">defined</span>(<span class="enscript-variable-name">NeXT_PDO</span>)
    <span class="enscript-comment">// GENERIC_OBJ_FILE
</span>    <span class="enscript-type">void</span> send_load_message_to_category(Category cat, <span class="enscript-type">void</span> *header_addr); 
    <span class="enscript-type">void</span> send_load_message_to_class(Class cls, <span class="enscript-type">void</span> *header_addr);
#<span class="enscript-reference">endif</span>

#<span class="enscript-reference">if</span> !<span class="enscript-reference">defined</span>(<span class="enscript-variable-name">__MACH__</span>)
<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> _objcSectionStruct {
    <span class="enscript-type">void</span>     **data;                   <span class="enscript-comment">/* Pointer to array  */</span>
    <span class="enscript-type">int</span>      count;                    <span class="enscript-comment">/* # of elements     */</span>
    <span class="enscript-type">int</span>      size;                     <span class="enscript-comment">/* sizeof an element */</span>
} objcSectionStruct;

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> _objcModHeader {
    <span class="enscript-type">char</span> *            name;
    objcSectionStruct Modules;
    objcSectionStruct Classes;
    objcSectionStruct Methods;
    objcSectionStruct Protocols;
    objcSectionStruct StringObjects;
} objcModHeader;
#<span class="enscript-reference">endif</span>


<span class="enscript-type">static</span> __inline__ <span class="enscript-type">int</span> <span class="enscript-function-name">_objc_strcmp</span>(<span class="enscript-type">const</span> <span class="enscript-type">unsigned</span> <span class="enscript-type">char</span> *s1, <span class="enscript-type">const</span> <span class="enscript-type">unsigned</span> <span class="enscript-type">char</span> *s2) {
    <span class="enscript-type">int</span> a, b, idx = 0;
    <span class="enscript-keyword">for</span> (;;) {
	a = s1[idx];
	b = s2[idx];
        <span class="enscript-keyword">if</span> (a != b || 0 == a) <span class="enscript-keyword">break</span>;
        idx++;
    }
    <span class="enscript-keyword">return</span> a - b;
}       

<span class="enscript-type">static</span> __inline__ <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span> <span class="enscript-function-name">_objc_strhash</span>(<span class="enscript-type">const</span> <span class="enscript-type">unsigned</span> <span class="enscript-type">char</span> *s) {
    <span class="enscript-type">unsigned</span> <span class="enscript-type">int</span> hash = 0;
    <span class="enscript-keyword">for</span> (;;) {
	<span class="enscript-type">int</span> a = *s++;
	<span class="enscript-keyword">if</span> (0 == a) <span class="enscript-keyword">break</span>;
	hash += (hash &lt;&lt; 8) + a;
    }
    <span class="enscript-keyword">return</span> hash;
}

#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* _OBJC_PRIVATE_H_ */</span>

</pre>
<hr />
</body></html>