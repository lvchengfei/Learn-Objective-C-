<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc-class.m</title>
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
<h1 style="margin:8px;" id="f1">objc-class.m&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
/***********************************************************************
 *	objc-<span class="enscript-type">class</span>.m
 *	Copyright 1988-1997, Apple Computer, Inc.
 *	Author:	s. naroff
 **********************************************************************/

/***********************************************************************
 * Imports.
 **********************************************************************/

#ifdef __MACH__
	#import &lt;mach/mach_interface.h&gt;
	#include &lt;mach-o/ldsyms.h&gt;
	#include &lt;mach-o/dyld.h&gt;
#endif

#ifdef WIN32
	#include &lt;io.h&gt;
	#include &lt;fcntl.h&gt;
	#include &lt;winnt-pdo.h&gt;
#<span class="enscript-keyword">else</span>
	#include &lt;sys/types.h&gt;
	#include &lt;unistd.h&gt;
	#include &lt;stdlib.h&gt;
	#include &lt;sys/uio.h&gt;
	#ifdef __svr4__
		#include &lt;fcntl.h&gt;
	#<span class="enscript-keyword">else</span>
		#include &lt;sys/fcntl.h&gt;
	#endif
#endif 

#<span class="enscript-keyword">if</span> defined(__svr4__) || defined(__hpux__) || defined(hpux)
	#import &lt;pdo.h&gt;
#endif

#import &lt;objc/Object.h&gt;
#import &lt;objc/objc-runtime.h&gt;
#import &quot;objc-private.h&quot;
#import &quot;hashtable2.h&quot;
#import &quot;maptable.h&quot;

#include &lt;sys/types.h&gt;

#include &lt;CoreFoundation/CFDictionary.h&gt;

// Needed functions <span class="enscript-type">not</span> in <span class="enscript-type">any</span> header file
size_t malloc_size (const void * ptr);

// Needed kernel interface
#import &lt;mach/mach.h&gt;
#ifdef __MACH__
#import &lt;mach/thread_status.h&gt;
#endif

// This is currently disabled in this file, because it is called a LOT here; turn it on when needed.
#<span class="enscript-keyword">if</span> 0 &amp;&amp; defined(__MACH__)
extern int ptrace(int, int, int, int); 
// ObjC is assigned the range 0xb000 - 0xbfff <span class="enscript-keyword">for</span> first parameter; this file 0xb300-0xb3ff
#<span class="enscript-keyword">else</span>
#define ptrace(a, b, c, d) do {} <span class="enscript-keyword">while</span> (0)
#endif

/***********************************************************************
 * Conditionals.
 **********************************************************************/

// Define PRELOAD_SUPERCLASS_CACHES to cause method lookups to add the
// method the appropriate superclass caches, in addition to the normal
// encaching in the subclass where the method was messaged.  Doing so
// will speed up messaging the same method from instances of the
// superclasses, but also uses up valuable cache space <span class="enscript-keyword">for</span> a speculative
// purpose
//#define PRELOAD_SUPERCLASS_CACHES

/***********************************************************************
 * Exports.
 **********************************************************************/

#ifdef OBJC_INSTRUMENTED
enum {
	CACHE_HISTOGRAM_SIZE	= 512
};

unsigned int	CacheHitHistogram <span class="enscript-type">[</span>CACHE_HISTOGRAM_SIZE<span class="enscript-type">]</span>;
unsigned int	CacheMissHistogram <span class="enscript-type">[</span>CACHE_HISTOGRAM_SIZE<span class="enscript-type">]</span>;
#endif

/***********************************************************************
 * Constants <span class="enscript-type">and</span> macros internal to this module.
 **********************************************************************/

// INIT_CACHE_SIZE <span class="enscript-type">and</span> INIT_META_CACHE_SIZE must be a <span class="enscript-type">power</span> of two
enum {
	INIT_CACHE_SIZE_LOG2		= 2,
	INIT_META_CACHE_SIZE_LOG2	= 2,
	INIT_CACHE_SIZE			= (1 &lt;&lt; INIT_CACHE_SIZE_LOG2),
	INIT_META_CACHE_SIZE		= (1 &lt;&lt; INIT_META_CACHE_SIZE_LOG2)
};

// Amount of space required <span class="enscript-keyword">for</span> count hash table buckets, knowing that
// one entry is embedded in the cache structure itself
#define TABLE_SIZE(count)	((count - 1) * sizeof(Method))

// Class state
#define ISCLASS(cls)		((((struct objc_class *) cls)-&gt;info &amp; CLS_CLASS) != 0)
#define ISMETA(cls)		((((struct objc_class *) cls)-&gt;info &amp; CLS_META) != 0)
#define GETMETA(cls)		(ISMETA(cls) ? ((struct objc_class *) cls) : ((struct objc_class *) cls)-&gt;<span class="enscript-type">isa</span>)
#define ISINITIALIZED(cls)	((GETMETA(cls)-&gt;info &amp; CLS_INITIALIZED) != 0)
#define MARKINITIALIZED(cls)	(GETMETA(cls)-&gt;info |= CLS_INITIALIZED)

/***********************************************************************
 * Types internal to this module.
 **********************************************************************/

#ifdef OBJC_INSTRUMENTED
struct CacheInstrumentation
{
	unsigned int	hitCount;		// cache lookup success tally
	unsigned int	hitProbes;		// <span class="enscript-type">sum</span> entries checked to hit
	unsigned int	maxHitProbes;		// <span class="enscript-type">max</span> entries checked to hit
	unsigned int	missCount;		// cache lookup no-<span class="enscript-type">find</span> tally
	unsigned int	missProbes;		// <span class="enscript-type">sum</span> entries checked to miss
	unsigned int	maxMissProbes;		// <span class="enscript-type">max</span> entries checked to miss
	unsigned int	flushCount;		// cache flush tally
	unsigned int	flushedEntries;		// <span class="enscript-type">sum</span> cache entries flushed
	unsigned int	maxFlushedEntries;	// <span class="enscript-type">max</span> cache entries flushed
};
typedef struct CacheInstrumentation	CacheInstrumentation;

// Cache instrumentation data follows table, so it is most compatible
#define CACHE_INSTRUMENTATION(cache)	(CacheInstrumentation *) &amp;cache-&gt;buckets<span class="enscript-type">[</span>cache-&gt;mask + 1<span class="enscript-type">]</span>;
#endif

/***********************************************************************
 * Function prototypes internal to this module.
 **********************************************************************/

static Ivar		class_getVariable		(Class cls, const <span class="enscript-type">char</span> * name);
static void		flush_caches			(Class cls, BOOL flush_meta);
static void		addClassToOriginalClass	(Class posingClass, Class originalClass);
static void		_objc_addOrigClass		(Class origClass);
static void		_freedHandler			(id self, SEL sel); 
static void		_nonexistentHandler		(id self, SEL sel);
static void		class_initialize		(Class clsDesc);
static void *	objc_malloc				(int byteCount);
static Cache	_cache_expand			(Class cls);
static int		LogObjCMessageSend		(BOOL isClassMethod, const <span class="enscript-type">char</span> * objectsClass, const <span class="enscript-type">char</span> * implementingClass, SEL selector);
static void		_cache_fill				(Class cls, Method smt, SEL sel);
static void		_cache_flush			(Class cls);
static Method	_class_lookupMethod		(Class cls, SEL sel);
static int		SubtypeUntil			(const <span class="enscript-type">char</span> * <span class="enscript-type">type</span>, <span class="enscript-type">char</span> <span class="enscript-keyword">end</span>); 
static const <span class="enscript-type">char</span> *	SkipFirstType		(const <span class="enscript-type">char</span> * <span class="enscript-type">type</span>); 

#ifdef OBJC_COLLECTING_CACHE
static unsigned long	_get_pc_for_thread	(mach_port_t thread);
static int		_collecting_in_critical	(void);
static void		_garbage_make_room		(void);
static void		_cache_collect_free		(void * data, BOOL tryCollect);
#endif

static void		_cache_print			(Cache cache);
static unsigned int	<span class="enscript-type">log2</span>				(unsigned int x);
static void		PrintCacheHeader		(void);
#ifdef OBJC_INSTRUMENTED
static void		PrintCacheHistogram		(<span class="enscript-type">char</span> * <span class="enscript-type">title</span>, unsigned int * firstEntry, unsigned int entryCount);
#endif

/***********************************************************************
 * Static data internal to this module.
 **********************************************************************/

// When _class_uncache is non-zero, cache growth copies the existing
// entries into the new (larger) cache.  When this flag is zero, new
// (larger) caches start out empty.
static int	_class_uncache		= 1;

// When _class_slow_grow is non-zero, <span class="enscript-type">any</span> given cache is actually grown
// only on the odd-numbered <span class="enscript-type">times</span> it becomes <span class="enscript-type">full</span>; on the even-numbered
// <span class="enscript-type">times</span>, it is simply emptied <span class="enscript-type">and</span> re-used.  When this flag is zero,
// caches are grown every time.
static int	_class_slow_grow	= 1;

// Locks <span class="enscript-keyword">for</span> cache access
#ifdef OBJC_COLLECTING_CACHE
// Held when adding an entry to the cache
static OBJC_DECLARE_LOCK(cacheUpdateLock);

// Held when freeing memory from garbage
static OBJC_DECLARE_LOCK(cacheCollectionLock);
#endif

// Held when looking in, adding to, <span class="enscript-type">or</span> freeing the cache.
#ifdef OBJC_COLLECTING_CACHE
// For speed, messageLock is <span class="enscript-type">not</span> held by the method dispatch code.
// Instead the cache freeing code checks thread PCs to ensure no
// one is dispatching.  messageLock is held, though, during less
// time critical operations.
#endif
OBJC_DECLARE_LOCK(messageLock);

CFMutableDictionaryRef _classIMPTables = NULL;

// When traceDuplicates is non-zero, _cacheFill checks whether the method
// being encached is already there.  The number of <span class="enscript-type">times</span> it finds a match
// is tallied in cacheFillDuplicates.  When traceDuplicatesVerbose is
// non-zero, each duplication is logged when found in this way.
#ifdef OBJC_COLLECTING_CACHE
static int	traceDuplicates		= 0;
static int	traceDuplicatesVerbose	= 0;
static int	cacheFillDuplicates	= 0;
#endif 

#ifdef OBJC_INSTRUMENTED
// Instrumentation
static unsigned int	LinearFlushCachesCount			= 0;
static unsigned int	LinearFlushCachesVisitedCount		= 0;
static unsigned int	MaxLinearFlushCachesVisitedCount	= 0;
static unsigned int	NonlinearFlushCachesCount		= 0;
static unsigned int	NonlinearFlushCachesClassCount		= 0;
static unsigned int	NonlinearFlushCachesVisitedCount	= 0;
static unsigned int	MaxNonlinearFlushCachesVisitedCount	= 0;
static unsigned int	IdealFlushCachesCount			= 0;
static unsigned int	MaxIdealFlushCachesCount		= 0;
#endif

// Method call logging
typedef int	(*ObjCLogProc)(BOOL, const <span class="enscript-type">char</span> *, const <span class="enscript-type">char</span> *, SEL);

static int			totalCacheFills		= 0;
static int			objcMsgLogFD		= (-1);
static ObjCLogProc	objcMsgLogProc		= &amp;LogObjCMessageSend;
static int			objcMsgLogEnabled	= 0;

// Error Messages
static const <span class="enscript-type">char</span>
	_errNoMem<span class="enscript-type">[</span><span class="enscript-type">]</span>					= &quot;failed -- out of memory(<span class="enscript-comment">%s, %u)&quot;,
</span>	_errAllocNil<span class="enscript-type">[</span><span class="enscript-type">]</span>				= &quot;allocating nil object&quot;,
	_errFreedObject<span class="enscript-type">[</span><span class="enscript-type">]</span>			= &quot;message <span class="enscript-comment">%s sent to freed object=0x%lx&quot;,
</span>	_errNonExistentObject<span class="enscript-type">[</span><span class="enscript-type">]</span>		= &quot;message <span class="enscript-comment">%s sent to non-existent object=0x%lx&quot;,
</span>	_errBadSel<span class="enscript-type">[</span><span class="enscript-type">]</span>				= &quot;invalid selector <span class="enscript-comment">%s&quot;,
</span>	_errNotSuper<span class="enscript-type">[</span><span class="enscript-type">]</span>				= &quot;<span class="enscript-type">[</span><span class="enscript-comment">%s poseAs:%s]: target not immediate superclass&quot;,
</span>	_errNewVars<span class="enscript-type">[</span><span class="enscript-type">]</span>				= &quot;<span class="enscript-type">[</span><span class="enscript-comment">%s poseAs:%s]: %s defines new instance variables&quot;;
</span>
/***********************************************************************
 * Information about multi-thread support:
 *
 * Since we do <span class="enscript-type">not</span> lock many operations <span class="enscript-type">which</span> walk the superclass, method
 * <span class="enscript-type">and</span> ivar chains, these chains must remain intact once a <span class="enscript-type">class</span> is published
 * by inserting it into the <span class="enscript-type">class</span> hashtable.  All modifications must be
 * atomic so that someone walking these chains will always geta valid
 * result.
 ***********************************************************************/
/***********************************************************************
 * A static empty cache.  All classes initially point at this cache.
 * When the first message is sent it misses in the cache, <span class="enscript-type">and</span> when
 * the cache is grown it checks <span class="enscript-keyword">for</span> this <span class="enscript-type">case</span> <span class="enscript-type">and</span> uses malloc rather
 * than realloc.  This avoids the need to check <span class="enscript-keyword">for</span> NULL caches in the
 * messenger.
 ***********************************************************************/

const struct objc_cache		emptyCache =
{
	0,				// mask
	0,				// occupied
	{ NULL }			// buckets
};

// Freed objects have their <span class="enscript-type">isa</span> <span class="enscript-type">set</span> to point to this dummy <span class="enscript-type">class</span>.
// This avoids the need to check <span class="enscript-keyword">for</span> Nil classes in the messenger.
static const struct objc_class freedObjectClass =
{
	Nil,				// <span class="enscript-type">isa</span>
	Nil,				// super_class
	&quot;FREED(id)&quot;,			// name
	0,				// <span class="enscript-type">version</span>
	0,				// info
	0,				// instance_size
	NULL,				// ivars
	NULL,				// methodLists
	(Cache) &amp;emptyCache,		// cache
	NULL				// protocols
};

static const struct objc_class nonexistentObjectClass =
{
	Nil,				// <span class="enscript-type">isa</span>
	Nil,				// super_class
	&quot;NONEXISTENT(id)&quot;,		// name
	0,				// <span class="enscript-type">version</span>
	0,				// info
	0,				// instance_size
	NULL,				// ivars
	NULL,				// methodLists
	(Cache) &amp;emptyCache,		// cache
	NULL				// protocols
};

/***********************************************************************
 * object_getClassName.
 **********************************************************************/
const <span class="enscript-type">char</span> *	object_getClassName		   (id		obj)
{
	// Even nil objects have a <span class="enscript-type">class</span> name, <span class="enscript-type">sort</span> of
	<span class="enscript-keyword">if</span> (obj == nil) 
		<span class="enscript-keyword">return</span> &quot;nil&quot;;

	// Retrieve name from object<span class="enscript-keyword">'</span>s <span class="enscript-type">class</span>
	<span class="enscript-keyword">return</span> ((struct objc_class *) obj-&gt;<span class="enscript-type">isa</span>)-&gt;name;
}

/***********************************************************************
 * object_getIndexedIvars.
 **********************************************************************/
void *		object_getIndexedIvars		   (id		obj)
{
	// ivars are tacked onto the <span class="enscript-keyword">end</span> of the object
	<span class="enscript-keyword">return</span> ((<span class="enscript-type">char</span> *) obj) + ((struct objc_class *) obj-&gt;<span class="enscript-type">isa</span>)-&gt;instance_size;
}


/***********************************************************************
 * _internal_class_createInstanceFromZone.  Allocate an instance of the
 * specified <span class="enscript-type">class</span> with the specified number of bytes <span class="enscript-keyword">for</span> indexed
 * variables, in the specified zone.  The <span class="enscript-type">isa</span> field is <span class="enscript-type">set</span> to the
 * <span class="enscript-type">class</span>, <span class="enscript-type">all</span> other fields are zeroed.
 **********************************************************************/
static id	_internal_class_createInstanceFromZone (Class		aClass,
						unsigned	nIvarBytes,
						void *	z) 
{
	id			obj; 
	register unsigned	byteCount;

	// Can<span class="enscript-keyword">'</span>t create something <span class="enscript-keyword">for</span> nothing
	<span class="enscript-keyword">if</span> (aClass == Nil)
	{
		__objc_error ((id) aClass, _errAllocNil, 0);
		<span class="enscript-keyword">return</span> nil;
	}

	// Allocate <span class="enscript-type">and</span> initialize
	byteCount = ((struct objc_class *) aClass)-&gt;instance_size + nIvarBytes;
	obj = (id) malloc_zone_calloc (z, 1, byteCount);
	<span class="enscript-keyword">if</span> (!obj)
	{
		__objc_error ((id) aClass, _errNoMem, ((struct objc_class *) aClass)-&gt;name, nIvarBytes);
		<span class="enscript-keyword">return</span> nil;
	}
	
	// Set the <span class="enscript-type">isa</span> pointer
	obj-&gt;<span class="enscript-type">isa</span> = aClass; 
	<span class="enscript-keyword">return</span> obj;
} 

/***********************************************************************
 * _internal_class_createInstance.  Allocate an instance of the specified
 * <span class="enscript-type">class</span> with the specified number of bytes <span class="enscript-keyword">for</span> indexed variables, in
 * the default zone, using _internal_class_createInstanceFromZone.
 **********************************************************************/
static id	_internal_class_createInstance	       (Class		aClass,
						unsigned	nIvarBytes) 
{
	<span class="enscript-keyword">return</span> _internal_class_createInstanceFromZone (aClass,
					nIvarBytes,
					malloc_default_zone ());
} 

id (*_poseAs)() = (id (*)())class_poseAs;
id (*_alloc)(Class, unsigned) = _internal_class_createInstance;
id (*_zoneAlloc)(Class, unsigned, void *) = _internal_class_createInstanceFromZone;

/***********************************************************************
 * class_createInstanceFromZone.  Allocate an instance of the specified
 * <span class="enscript-type">class</span> with the specified number of bytes <span class="enscript-keyword">for</span> indexed variables, in
 * the specified zone, using _zoneAlloc.
 **********************************************************************/
id	class_createInstanceFromZone   (Class		aClass,
					unsigned	nIvarBytes,
					void *	z) 
{
	// _zoneAlloc can be overridden, but is initially <span class="enscript-type">set</span> to
	// _internal_class_createInstanceFromZone
	<span class="enscript-keyword">return</span> (*_zoneAlloc) (aClass, nIvarBytes, z);
} 

/***********************************************************************
 * class_createInstance.  Allocate an instance of the specified <span class="enscript-type">class</span> with
 * the specified number of bytes <span class="enscript-keyword">for</span> indexed variables, using _alloc.
 **********************************************************************/
id	class_createInstance	       (Class		aClass,
					unsigned	nIvarBytes) 
{
	// _alloc can be overridden, but is initially <span class="enscript-type">set</span> to
	// _internal_class_createInstance
	<span class="enscript-keyword">return</span> (*_alloc) (aClass, nIvarBytes);
} 

/***********************************************************************
 * class_setVersion.  Record the specified <span class="enscript-type">version</span> with the <span class="enscript-type">class</span>.
 **********************************************************************/
void	class_setVersion	       (Class		aClass,
					int		<span class="enscript-type">version</span>)
{
	((struct objc_class *) aClass)-&gt;<span class="enscript-type">version</span> = <span class="enscript-type">version</span>;
}

/***********************************************************************
 * class_getVersion.  Return the <span class="enscript-type">version</span> recorded with the <span class="enscript-type">class</span>.
 **********************************************************************/
int	class_getVersion	       (Class		aClass)
{
	<span class="enscript-keyword">return</span> ((struct objc_class *) aClass)-&gt;<span class="enscript-type">version</span>;
}

static void _addListIMPsToTable(CFMutableDictionaryRef table, struct objc_method_list *mlist, Class cls, void **iterator) {
    int <span class="enscript-type">i</span>;
    struct objc_method_list *new_mlist;
    <span class="enscript-keyword">if</span> (!mlist) <span class="enscript-keyword">return</span>;
    /* Work from <span class="enscript-keyword">end</span> of list so that categories override */
    new_mlist = _class_inlinedNextMethodList(cls, iterator);
    _addListIMPsToTable(table, new_mlist, cls, iterator);
    <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; mlist-&gt;method_count; <span class="enscript-type">i</span>++) {
	CFDictionarySetValue(table, mlist-&gt;method_list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>.method_name, mlist-&gt;method_list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>.method_imp);
    }
}

static void _addClassIMPsToTable(CFMutableDictionaryRef table, Class cls) {
    struct objc_method_list *mlist;
    void *iterator = 0;
#ifdef INCLUDE_SUPER_IMPS_IN_IMP_TABLE
    <span class="enscript-keyword">if</span> (cls-&gt;super_class) {	/* Do superclass first so subclass overrides */
	CFMutableDictionaryRef super_table = CFDictionaryGetValue(_classIMPTables, cls-&gt;super_class);
	<span class="enscript-keyword">if</span> (super_table) {
	    CFIndex cnt;
	    const void **keys, **values, *buffer1<span class="enscript-type">[</span>128<span class="enscript-type">]</span>, *buffer2<span class="enscript-type">[</span>128<span class="enscript-type">]</span>;
	    cnt = CFDictionaryGetCount(super_table);
	    keys = (cnt &lt;= 128) ? buffer1 : CFAllocatorAllocate(NULL, cnt * sizeof(void *), 0);
	    values = (cnt &lt;= 128) ? buffer2 : CFAllocatorAllocate(NULL, cnt * sizeof(void *), 0);
	    CFDictionaryGetKeysAndValues(super_table, keys, values);
	    <span class="enscript-keyword">while</span> (cnt--) {
		CFDictionarySetValue(table, keys<span class="enscript-type">[</span>cnt<span class="enscript-type">]</span>, values<span class="enscript-type">[</span>cnt<span class="enscript-type">]</span>);
	    }
	    <span class="enscript-keyword">if</span> (keys != buffer1) CFAllocatorDeallocate(NULL, keys);
	    <span class="enscript-keyword">if</span> (values != buffer2) CFAllocatorDeallocate(NULL, values);
	} <span class="enscript-keyword">else</span> {
	    _addClassIMPsToTable(table, cls-&gt;super_class);
	}
    }
#endif
    mlist = _class_inlinedNextMethodList(cls, &amp;iterator);
    _addListIMPsToTable(table, mlist, cls, &amp;iterator);
}

CFMutableDictionaryRef _getClassIMPTable(Class cls) {
    CFMutableDictionaryRef table;
    <span class="enscript-keyword">if</span> (NULL == _classIMPTables) {
	// maps Classes to mutable dictionaries
	_classIMPTables = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
    }
    table = (CFMutableDictionaryRef)CFDictionaryGetValue(_classIMPTables, cls);
    // IMP table maps SELs to IMPS
    <span class="enscript-keyword">if</span> (NULL == table) {
	table = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
	_addClassIMPsToTable(table, cls);
	CFDictionaryAddValue(_classIMPTables, cls, table);
    }
    <span class="enscript-keyword">return</span> table;
}

static <span class="enscript-type">inline</span> Method _findNamedMethodInList(struct objc_method_list * mlist, const <span class="enscript-type">char</span> *meth_name) {
    int <span class="enscript-type">i</span>;
    <span class="enscript-keyword">if</span> (!mlist) <span class="enscript-keyword">return</span> NULL;
    <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; mlist-&gt;method_count; <span class="enscript-type">i</span>++) {
	Method m = &amp;mlist-&gt;method_list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;
	<span class="enscript-keyword">if</span> (*((const <span class="enscript-type">char</span> *)m-&gt;method_name) == *meth_name &amp;&amp; 0 == <span class="enscript-type">strcmp</span>((const <span class="enscript-type">char</span> *)(m-&gt;method_name), meth_name)) {
	    <span class="enscript-keyword">return</span> m;
	}
    }
    <span class="enscript-keyword">return</span> NULL;
}

/* These next three functions are the heart of ObjC method lookup. */
static <span class="enscript-type">inline</span> Method _findMethodInList(struct objc_method_list * mlist, SEL sel) {
    int <span class="enscript-type">i</span>;
    <span class="enscript-keyword">if</span> (!mlist) <span class="enscript-keyword">return</span> NULL;
    <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; mlist-&gt;method_count; <span class="enscript-type">i</span>++) {
	Method m = &amp;mlist-&gt;method_list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;
	<span class="enscript-keyword">if</span> (m-&gt;method_name == sel) {
	    <span class="enscript-keyword">return</span> m;
	}
    }
    <span class="enscript-keyword">return</span> NULL;
}

static <span class="enscript-type">inline</span> Method _findMethodInClass(Class cls, SEL sel) {
    struct objc_method_list *mlist;
    void *iterator = 0;
    <span class="enscript-keyword">while</span> ((mlist = _class_inlinedNextMethodList(cls, &amp;iterator))) {
	Method m = _findMethodInList(mlist, sel);
	<span class="enscript-keyword">if</span> (m) <span class="enscript-keyword">return</span> m;
    }
    <span class="enscript-keyword">return</span> NULL;
}

static <span class="enscript-type">inline</span> Method _getMethod(Class cls, SEL sel) {
    <span class="enscript-keyword">for</span> (; cls; cls = cls-&gt;super_class) {
        Method m = _findMethodInClass(cls, sel);
	<span class="enscript-keyword">if</span> (m) <span class="enscript-keyword">return</span> m;
    }
    <span class="enscript-keyword">return</span> NULL;
}


/***********************************************************************
 * class_getInstanceMethod.  Return the instance method <span class="enscript-keyword">for</span> the
 * specified <span class="enscript-type">class</span> <span class="enscript-type">and</span> selector.
 **********************************************************************/
Method		class_getInstanceMethod	       (Class		aClass,
						SEL		aSelector)
{
	// Need both a <span class="enscript-type">class</span> <span class="enscript-type">and</span> a selector
	<span class="enscript-keyword">if</span> (!aClass || !aSelector)
		<span class="enscript-keyword">return</span> NULL;

	// Go to the <span class="enscript-type">class</span>
	<span class="enscript-keyword">return</span> _getMethod (aClass, aSelector);
}

/***********************************************************************
 * class_getClassMethod.  Return the <span class="enscript-type">class</span> method <span class="enscript-keyword">for</span> the specified
 * <span class="enscript-type">class</span> <span class="enscript-type">and</span> selector.
 **********************************************************************/
Method		class_getClassMethod	       (Class		aClass,
						SEL		aSelector)
{
	// Need both a <span class="enscript-type">class</span> <span class="enscript-type">and</span> a selector
	<span class="enscript-keyword">if</span> (!aClass || !aSelector)
		<span class="enscript-keyword">return</span> NULL;

	// Go to the <span class="enscript-type">class</span> <span class="enscript-type">or</span> <span class="enscript-type">isa</span>
	<span class="enscript-keyword">return</span> _getMethod (GETMETA(aClass), aSelector);
}

/***********************************************************************
 * class_getVariable.  Return the named instance variable.
 **********************************************************************/
static Ivar	class_getVariable	       (Class		cls,
						const <span class="enscript-type">char</span> *	name)
{
	struct objc_class *	thisCls;

	// Outer loop - search the <span class="enscript-type">class</span> <span class="enscript-type">and</span> its superclasses
	<span class="enscript-keyword">for</span> (thisCls = cls; thisCls != Nil; thisCls = ((struct objc_class *) thisCls)-&gt;super_class)
	{
		int	index;
		Ivar	thisIvar;

		// Skip <span class="enscript-type">class</span> having no ivars
		<span class="enscript-keyword">if</span> (!thisCls-&gt;ivars)
			continue;

		// Inner loop - search the given <span class="enscript-type">class</span>
		thisIvar = &amp;thisCls-&gt;ivars-&gt;ivar_list<span class="enscript-type">[</span>0<span class="enscript-type">]</span>;
		<span class="enscript-keyword">for</span> (index = 0; index &lt; thisCls-&gt;ivars-&gt;ivar_count; index += 1)
		{
			// Check this ivar<span class="enscript-keyword">'</span>s name.  Be careful because the
			// compiler generates ivar entries with NULL ivar_name
			// (e.g. <span class="enscript-keyword">for</span> anonymous bit fields).
			<span class="enscript-keyword">if</span> ((thisIvar-&gt;ivar_name) &amp;&amp;
			    (<span class="enscript-type">strcmp</span> (name, thisIvar-&gt;ivar_name) == 0))
				<span class="enscript-keyword">return</span> thisIvar;

			// Move to next ivar
			thisIvar += 1;
		}
	}

	// Not found
	<span class="enscript-keyword">return</span> NULL;
}

/***********************************************************************
 * class_getInstanceVariable.  Return the named instance variable.
 *
 * Someday add class_getClassVariable (). 
 **********************************************************************/
Ivar	class_getInstanceVariable	       (Class		aClass,
						const <span class="enscript-type">char</span> *	name)
{
	// Must have a <span class="enscript-type">class</span> <span class="enscript-type">and</span> a name
	<span class="enscript-keyword">if</span> (!aClass || !name)
		<span class="enscript-keyword">return</span> NULL;

	// Look it up
	<span class="enscript-keyword">return</span> class_getVariable (aClass, name);	
}

/***********************************************************************
 * flush_caches.  Flush the instance <span class="enscript-type">and</span> optionally <span class="enscript-type">class</span> method caches
 * of cls <span class="enscript-type">and</span> <span class="enscript-type">all</span> its subclasses.
 *
 * Specifying Nil <span class="enscript-keyword">for</span> the <span class="enscript-type">class</span> &quot;<span class="enscript-type">all</span> classes.&quot;
 **********************************************************************/
static void	flush_caches	       (Class		cls,
					BOOL		flush_meta)
{
	int		numClasses = 0, newNumClasses;
	struct objc_class * *		classes = NULL;
	int		<span class="enscript-type">i</span>;
	struct objc_class *		clsObject;
#ifdef OBJC_INSTRUMENTED
	unsigned int	classesVisited;
	unsigned int	subclassCount;
#endif

	// Do nothing <span class="enscript-keyword">if</span> <span class="enscript-type">class</span> has no cache
	<span class="enscript-keyword">if</span> (cls &amp;&amp; !((struct objc_class *) cls)-&gt;cache)
		<span class="enscript-keyword">return</span>;

	newNumClasses = objc_getClassList((Class *)NULL, 0);
	<span class="enscript-keyword">while</span> (numClasses &lt; newNumClasses) {
		numClasses = newNumClasses;
		classes = realloc(classes, sizeof(Class) * numClasses);
		newNumClasses = objc_getClassList((Class *)classes, numClasses);
	}
	numClasses = newNumClasses;

	// Handle nil <span class="enscript-type">and</span> root instance <span class="enscript-type">class</span> specially: flush <span class="enscript-type">all</span>
	// instance <span class="enscript-type">and</span> <span class="enscript-type">class</span> method caches.  Nice that this
	// loop is linear vs the N-squared loop just below.	
	<span class="enscript-keyword">if</span> (!cls || !((struct objc_class *) cls)-&gt;super_class)
	{
#ifdef OBJC_INSTRUMENTED
		LinearFlushCachesCount += 1;
		classesVisited = 0;
		subclassCount = 0;
#endif
		// Traverse <span class="enscript-type">all</span> classes in the hash table
		<span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; numClasses; <span class="enscript-type">i</span>++)
		{
			struct objc_class *		metaClsObject;
#ifdef OBJC_INSTRUMENTED
			classesVisited += 1;
#endif
			clsObject = classes<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;
			
			// Skip <span class="enscript-type">class</span> that is known <span class="enscript-type">not</span> to be a subclass of this root
			// (the <span class="enscript-type">isa</span> pointer of <span class="enscript-type">any</span> meta <span class="enscript-type">class</span> points to the meta <span class="enscript-type">class</span>
			// of the root).
			// NOTE: When is an <span class="enscript-type">isa</span> pointer of a hash tabled <span class="enscript-type">class</span> ever nil?
			metaClsObject = ((struct objc_class *) clsObject)-&gt;<span class="enscript-type">isa</span>;
			<span class="enscript-keyword">if</span> (cls &amp;&amp; metaClsObject &amp;&amp; (((struct objc_class *) metaClsObject)-&gt;<span class="enscript-type">isa</span> != ((struct objc_class *) metaClsObject)-&gt;<span class="enscript-type">isa</span>))
				continue;

#ifdef OBJC_INSTRUMENTED
			subclassCount += 1;
#endif

			// Be careful of classes that do <span class="enscript-type">not</span> yet have caches
			<span class="enscript-keyword">if</span> (((struct objc_class *) clsObject)-&gt;cache)
				_cache_flush (clsObject);
			<span class="enscript-keyword">if</span> (flush_meta &amp;&amp; metaClsObject &amp;&amp; ((struct objc_class *) metaClsObject)-&gt;cache)
				_cache_flush (((struct objc_class *) clsObject)-&gt;<span class="enscript-type">isa</span>);
		}
#ifdef OBJC_INSTRUMENTED
		LinearFlushCachesVisitedCount += classesVisited;
		<span class="enscript-keyword">if</span> (classesVisited &gt; MaxLinearFlushCachesVisitedCount)
			MaxLinearFlushCachesVisitedCount = classesVisited;
		IdealFlushCachesCount += subclassCount;
		<span class="enscript-keyword">if</span> (subclassCount &gt; MaxIdealFlushCachesCount)
			MaxIdealFlushCachesCount = subclassCount;
#endif

		free(classes);
		<span class="enscript-keyword">return</span>;
	}

	// Outer loop - flush <span class="enscript-type">any</span> cache that could <span class="enscript-type">now</span> <span class="enscript-type">get</span> a method from
	// cls (<span class="enscript-type">i</span>.e. the cache associated with cls <span class="enscript-type">and</span> <span class="enscript-type">any</span> of its subclasses).
#ifdef OBJC_INSTRUMENTED
	NonlinearFlushCachesCount += 1;
	classesVisited = 0;
	subclassCount = 0;
#endif
	<span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; numClasses; <span class="enscript-type">i</span>++)
	{
		struct objc_class *		clsIter;

#ifdef OBJC_INSTRUMENTED
		NonlinearFlushCachesClassCount += 1;
#endif
		clsObject = classes<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;

		// Inner loop - Process a given <span class="enscript-type">class</span>
		clsIter = clsObject;
		<span class="enscript-keyword">while</span> (clsIter)
		{

#ifdef OBJC_INSTRUMENTED
			classesVisited += 1;
#endif
			// Flush clsObject instance method cache <span class="enscript-keyword">if</span>
			// clsObject is a subclass of cls, <span class="enscript-type">or</span> is cls itself
			// Flush the <span class="enscript-type">class</span> method cache <span class="enscript-keyword">if</span> that was asked <span class="enscript-keyword">for</span>
			<span class="enscript-keyword">if</span> (clsIter == cls)
			{
#ifdef OBJC_INSTRUMENTED
				subclassCount += 1;
#endif
				_cache_flush (clsObject);
				<span class="enscript-keyword">if</span> (flush_meta)
					_cache_flush (clsObject-&gt;<span class="enscript-type">isa</span>);
				
				<span class="enscript-keyword">break</span>;

			}
			
			// Flush clsObject <span class="enscript-type">class</span> method cache <span class="enscript-keyword">if</span> cls is 
			// the meta <span class="enscript-type">class</span> of clsObject <span class="enscript-type">or</span> of one
			// of clsObject<span class="enscript-keyword">'</span>s superclasses
			<span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> (clsIter-&gt;<span class="enscript-type">isa</span> == cls)
			{
#ifdef OBJC_INSTRUMENTED
				subclassCount += 1;
#endif
				_cache_flush (clsObject-&gt;<span class="enscript-type">isa</span>);
				<span class="enscript-keyword">break</span>;
			}
			
			// Move up superclass chain
			<span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> (ISINITIALIZED(clsIter))
				clsIter = clsIter-&gt;super_class;
			
			// clsIter is <span class="enscript-type">not</span> initialized, so its cache
			// must be empty.  This happens only when
			// clsIter == clsObject, because
			// superclasses are initialized before
			// subclasses, <span class="enscript-type">and</span> this loop traverses
			// from sub- to super- classes.
			<span class="enscript-keyword">else</span>
				<span class="enscript-keyword">break</span>;
		}
	}
#ifdef OBJC_INSTRUMENTED
	NonlinearFlushCachesVisitedCount += classesVisited;
	<span class="enscript-keyword">if</span> (classesVisited &gt; MaxNonlinearFlushCachesVisitedCount)
		MaxNonlinearFlushCachesVisitedCount = classesVisited;
	IdealFlushCachesCount += subclassCount;
	<span class="enscript-keyword">if</span> (subclassCount &gt; MaxIdealFlushCachesCount)
		MaxIdealFlushCachesCount = subclassCount;
#endif

	// Relinquish access to <span class="enscript-type">class</span> hash table
	free(classes);
}

/***********************************************************************
 * _objc_flush_caches.  Flush the caches of the specified <span class="enscript-type">class</span> <span class="enscript-type">and</span> <span class="enscript-type">any</span>
 * of its subclasses.  If cls is a meta-<span class="enscript-type">class</span>, only meta-<span class="enscript-type">class</span> (<span class="enscript-type">i</span>.e.
 * <span class="enscript-type">class</span> method) caches are flushed.  If cls is an instance-<span class="enscript-type">class</span>, both
 * instance-<span class="enscript-type">class</span> <span class="enscript-type">and</span> meta-<span class="enscript-type">class</span> caches are flushed.
 **********************************************************************/
void		_objc_flush_caches	       (Class		cls)
{
	flush_caches (cls, YES);
}

/***********************************************************************
 * do_not_remove_this_dummy_function.
 **********************************************************************/
void		do_not_remove_this_dummy_function	   (void)
{
	(void) class_nextMethodList (NULL, NULL);
}

/***********************************************************************
 * class_nextMethodList.
 *
 * usage:
 * void *	iterator = 0;
 * <span class="enscript-keyword">while</span> (class_nextMethodList (cls, &amp;iterator)) {<span class="enscript-keyword">...</span>}
 **********************************************************************/
OBJC_EXPORT struct objc_method_list * class_nextMethodList (Class	cls,
							    void **	it)
{
    <span class="enscript-keyword">return</span> _class_inlinedNextMethodList(cls, it);
}

/***********************************************************************
 * _dummy.
 **********************************************************************/
void		_dummy		   (void)
{
	(void) class_nextMethodList (Nil, NULL);
}

/***********************************************************************
 * class_addMethods.
 *
 * Formerly class_addInstanceMethods ()
 **********************************************************************/
void	class_addMethods       (Class				cls,
				struct objc_method_list *	meths)
{
	// Insert atomically.
	_objc_insertMethods (meths, &amp;((struct objc_class *) cls)-&gt;methodLists);
	
	// Must flush when dynamically adding methods.  No need to flush
	// <span class="enscript-type">all</span> the <span class="enscript-type">class</span> method caches.  If cls is a meta <span class="enscript-type">class</span>, though,
	// this will still flush it <span class="enscript-type">and</span> <span class="enscript-type">any</span> of its sub-meta classes.
	flush_caches (cls, NO);
}

/***********************************************************************
 * class_addClassMethods.
 *
 * Obsolete (<span class="enscript-keyword">for</span> binary compatibility only).
 **********************************************************************/
void	class_addClassMethods  (Class				cls,
				struct objc_method_list *	meths)
{
	class_addMethods (((struct objc_class *) cls)-&gt;<span class="enscript-type">isa</span>, meths);
}

/***********************************************************************
 * class_removeMethods.
 **********************************************************************/
void	class_removeMethods    (Class				cls,
				struct objc_method_list *	meths)
{
	// Remove atomically.
	_objc_removeMethods (meths, &amp;((struct objc_class *) cls)-&gt;methodLists);
	
	// Must flush when dynamically removing methods.  No need to flush
	// <span class="enscript-type">all</span> the <span class="enscript-type">class</span> method caches.  If cls is a meta <span class="enscript-type">class</span>, though,
	// this will still flush it <span class="enscript-type">and</span> <span class="enscript-type">any</span> of its sub-meta classes.
	flush_caches (cls, NO); 
}

/***********************************************************************
 * addClassToOriginalClass.  Add to a hash table of classes involved in
 * a posing situation.  We use this when we need to <span class="enscript-type">get</span> to the &quot;original&quot; 
 * <span class="enscript-type">class</span> <span class="enscript-keyword">for</span> some particular name through the <span class="enscript-keyword">function</span> objc_getOrigClass.
 * For instance, the implementation of <span class="enscript-type">[</span>super <span class="enscript-keyword">...</span><span class="enscript-type">]</span> will use this to be
 * sure that it gets <span class="enscript-type">hold</span> of the correct super <span class="enscript-type">class</span>, so that no infinite
 * loops will occur <span class="enscript-keyword">if</span> the <span class="enscript-type">class</span> it appears in is involved in posing.
 *
 * We use the classLock to guard the hash table.
 *
 * See tracker bug #51856.
 **********************************************************************/

static NXMapTable *	posed_class_hash = NULL;
static NXMapTable *	posed_class_to_original_class_hash = NULL;

static void	addClassToOriginalClass	       (Class	posingClass,
						Class	originalClass)
{
	// Install hash table when it is first needed
	<span class="enscript-keyword">if</span> (!posed_class_to_original_class_hash)
	{
		posed_class_to_original_class_hash =
			NXCreateMapTableFromZone (NXPtrValueMapPrototype,
						  8,
						  _objc_create_zone ());
	}

	// Add pose to hash table
	NXMapInsert (posed_class_to_original_class_hash,
		     posingClass,
		     originalClass);
}

/***********************************************************************
 * getOriginalClassForPosingClass.
 **********************************************************************/
Class	getOriginalClassForPosingClass	(Class	posingClass)
{
	<span class="enscript-keyword">return</span> NXMapGet (posed_class_to_original_class_hash, posingClass);
}

/***********************************************************************
 * objc_getOrigClass.
 **********************************************************************/
Class	objc_getOrigClass		   (const <span class="enscript-type">char</span> *	name)
{
	struct objc_class *	ret;

	// Look <span class="enscript-keyword">for</span> <span class="enscript-type">class</span> among the posers
	ret = Nil;
	OBJC_LOCK(&amp;classLock);
	<span class="enscript-keyword">if</span> (posed_class_hash)
		ret = (Class) NXMapGet (posed_class_hash, name);
	OBJC_UNLOCK(&amp;classLock);
	<span class="enscript-keyword">if</span> (ret)
		<span class="enscript-keyword">return</span> ret;

	// Not a poser.  Do a normal lookup.
	ret = objc_getClass (name);
	<span class="enscript-keyword">if</span> (!ret)
		_objc_inform (&quot;<span class="enscript-type">class</span> `<span class="enscript-comment">%s' not linked into application&quot;, name);
</span>
	<span class="enscript-keyword">return</span> ret;
}

/***********************************************************************
 * _objc_addOrigClass.  This <span class="enscript-keyword">function</span> is only used from class_poseAs.
 * Registers the original <span class="enscript-type">class</span> names, before they <span class="enscript-type">get</span> obscured by 
 * posing, so that <span class="enscript-type">[</span>super ..<span class="enscript-type">]</span> will work correctly from categories 
 * in posing classes <span class="enscript-type">and</span> in categories in classes being posed <span class="enscript-keyword">for</span>.
 **********************************************************************/
static void	_objc_addOrigClass	   (Class	origClass)
{
	OBJC_LOCK(&amp;classLock);
	
	// Create the poser<span class="enscript-keyword">'</span>s hash table on first use
	<span class="enscript-keyword">if</span> (!posed_class_hash)
	{
		posed_class_hash = NXCreateMapTableFromZone (NXStrValueMapPrototype,
							     8,
							     _objc_create_zone ());
	}

	// Add the named <span class="enscript-type">class</span> iff it is <span class="enscript-type">not</span> already there (<span class="enscript-type">or</span> collides?)
	<span class="enscript-keyword">if</span> (NXMapGet (posed_class_hash, ((struct objc_class *)origClass)-&gt;name) == 0)
		NXMapInsert (posed_class_hash, ((struct objc_class *)origClass)-&gt;name, origClass);

	OBJC_UNLOCK(&amp;classLock);
}

/***********************************************************************
 * class_poseAs.
 *
 * !!! class_poseAs () does <span class="enscript-type">not</span> currently flush <span class="enscript-type">any</span> caches.
 **********************************************************************/
Class		class_poseAs	       (Class		imposter,
					Class		original) 
{
	struct objc_class * clsObject;
	<span class="enscript-type">char</span>			imposterName<span class="enscript-type">[</span>256<span class="enscript-type">]</span>; 
	<span class="enscript-type">char</span> *			imposterNamePtr; 
	NXHashTable *		class_hash;
	NXHashState		state;
	struct objc_class * 			copy;
#ifdef OBJC_CLASS_REFS
	unsigned int		hidx;
	unsigned int		hdrCount;
	header_info *		hdrVector;

	// Get these <span class="enscript-type">now</span> before locking, to minimize impact
	hdrCount  = _objc_headerCount ();
	hdrVector = _objc_headerVector (NULL);
#endif

	// Trivial <span class="enscript-type">case</span> is easy
	<span class="enscript-keyword">if</span> (imposter == original) 
		<span class="enscript-keyword">return</span> imposter;

	// Imposter must be an immediate subclass of the original
	<span class="enscript-keyword">if</span> (((struct objc_class *)imposter)-&gt;super_class != original)
		<span class="enscript-keyword">return</span> (Class) <span class="enscript-type">[</span>(id) imposter <span class="enscript-keyword">error</span>:_errNotSuper, 
				((struct objc_class *)imposter)-&gt;name, ((struct objc_class *)original)-&gt;name<span class="enscript-type">]</span>;
	
	// Can<span class="enscript-keyword">'</span>t pose when you have instance variables (how could it work?)
	<span class="enscript-keyword">if</span> (((struct objc_class *)imposter)-&gt;ivars)
		<span class="enscript-keyword">return</span> (Class) <span class="enscript-type">[</span>(id) imposter <span class="enscript-keyword">error</span>:_errNewVars, ((struct objc_class *)imposter)-&gt;name, 
				((struct objc_class *)original)-&gt;name, ((struct objc_class *)imposter)-&gt;name<span class="enscript-type">]</span>;

	// Build a string to use to replace the name of the original <span class="enscript-type">class</span>.
	strcpy (imposterName, &quot;_<span class="enscript-comment">%&quot;); 
</span>	<span class="enscript-type">strcat</span> (imposterName, ((struct objc_class *)original)-&gt;name);
	imposterNamePtr = objc_malloc (strlen (imposterName)+1);
	strcpy (imposterNamePtr, imposterName);

	// We lock the <span class="enscript-type">class</span> hashtable, so we are thread safe with respect to
	// calls to objc_getClass ().  However, the <span class="enscript-type">class</span> names are <span class="enscript-type">not</span>
	// changed atomically, nor are <span class="enscript-type">all</span> of the subclasses updated
	// atomically.  I have ordered the operations so that you will
	// never crash, but you may <span class="enscript-type">get</span> inconsistent results<span class="enscript-keyword">...</span>.

	// Register the original <span class="enscript-type">class</span> so that <span class="enscript-type">[</span>super ..<span class="enscript-type">]</span> knows
	// exactly <span class="enscript-type">which</span> classes are the &quot;original&quot; classes.
	_objc_addOrigClass (original);
	_objc_addOrigClass (imposter);

	OBJC_LOCK(&amp;classLock);

	class_hash = objc_getClasses ();

	// Remove both the imposter <span class="enscript-type">and</span> the original <span class="enscript-type">class</span>.
	NXHashRemove (class_hash, imposter);
	NXHashRemove (class_hash, original);

	// Copy the imposter, so that the imposter can continue
	// its normal life in addition to changing the behavior of
	// the original.  As a hack we don<span class="enscript-keyword">'</span>t bother to copy the metaclass.
	// For some reason we modify the original rather than the copy.
	copy = (*_zoneAlloc)(imposter-&gt;<span class="enscript-type">isa</span>, sizeof(struct objc_class), _objc_create_zone());
	memmove(copy, imposter, sizeof(struct objc_class));

	NXHashInsert (class_hash, copy);
	addClassToOriginalClass (imposter, copy);

	// Mark the imposter as such
	CLS_SETINFO(((struct objc_class *)imposter), CLS_POSING);
	CLS_SETINFO(((struct objc_class *)imposter)-&gt;<span class="enscript-type">isa</span>, CLS_POSING);

	// Change the name of the imposter to that of the original <span class="enscript-type">class</span>.
	((struct objc_class *)imposter)-&gt;name		= ((struct objc_class *)original)-&gt;name;
	((struct objc_class *)imposter)-&gt;<span class="enscript-type">isa</span>-&gt;name = ((struct objc_class *)original)-&gt;<span class="enscript-type">isa</span>-&gt;name;

	// Also copy the <span class="enscript-type">version</span> field to avoid archiving problems.
	((struct objc_class *)imposter)-&gt;<span class="enscript-type">version</span> = ((struct objc_class *)original)-&gt;<span class="enscript-type">version</span>;

	// Change <span class="enscript-type">all</span> subclasses of the original to point to the imposter.
	state = NXInitHashState (class_hash);
	<span class="enscript-keyword">while</span> (NXNextHashState (class_hash, &amp;state, (void **) &amp;clsObject))
	{
		<span class="enscript-keyword">while</span>  ((clsObject) &amp;&amp; (clsObject != imposter) &amp;&amp;
			(clsObject != copy))
			{
			<span class="enscript-keyword">if</span> (clsObject-&gt;super_class == original)
			{
				clsObject-&gt;super_class = imposter;
				clsObject-&gt;<span class="enscript-type">isa</span>-&gt;super_class = ((struct objc_class *)imposter)-&gt;<span class="enscript-type">isa</span>;
				// We must flush caches here!
				<span class="enscript-keyword">break</span>;
			}
			
			clsObject = clsObject-&gt;super_class;
		}
	}

#ifdef OBJC_CLASS_REFS
	// Replace the original with the imposter in <span class="enscript-type">all</span> <span class="enscript-type">class</span> refs
	// Major loop - process <span class="enscript-type">all</span> headers
	<span class="enscript-keyword">for</span> (hidx = 0; hidx &lt; hdrCount; hidx += 1)
	{
		Class *		cls_refs;
		unsigned int	refCount;
		unsigned int	index;
		
		// Get refs associated with this header
		cls_refs = (Class *) _getObjcClassRefs ((headerType *) hdrVector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.mhdr, &amp;refCount);
		<span class="enscript-keyword">if</span> (!cls_refs || !refCount)
			continue;

		// Minor loop - process this header<span class="enscript-keyword">'</span>s refs
		cls_refs = (Class *) ((unsigned long) cls_refs + hdrVector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.image_slide);
		<span class="enscript-keyword">for</span> (index = 0; index &lt; refCount; index += 1)
		{
			<span class="enscript-keyword">if</span> (cls_refs<span class="enscript-type">[</span>index<span class="enscript-type">]</span> == original)
				cls_refs<span class="enscript-type">[</span>index<span class="enscript-type">]</span> = imposter;
		}
	}
#endif // OBJC_CLASS_REFS

	// Change the name of the original <span class="enscript-type">class</span>.
	((struct objc_class *)original)-&gt;name	    = imposterNamePtr + 1;
	((struct objc_class *)original)-&gt;<span class="enscript-type">isa</span>-&gt;name = imposterNamePtr;
	
	// Restore the imposter <span class="enscript-type">and</span> the original <span class="enscript-type">class</span> with their new names.
	NXHashInsert (class_hash, imposter);
	NXHashInsert (class_hash, original);
	
	OBJC_UNLOCK(&amp;classLock);
	
	<span class="enscript-keyword">return</span> imposter;
}

/***********************************************************************
 * _freedHandler.
 **********************************************************************/
static void	_freedHandler	       (id		self,
					SEL		sel) 
{
	__objc_error (self, _errFreedObject, SELNAME(sel), self);
}

/***********************************************************************
 * _nonexistentHandler.
 **********************************************************************/
static void	_nonexistentHandler    (id		self,
					SEL		sel)
{
	__objc_error (self, _errNonExistentObject, SELNAME(sel), self);
}

/***********************************************************************
 * class_initialize.  Send the <span class="enscript-string">'initialize'</span> message on demand to <span class="enscript-type">any</span>
 * uninitialized <span class="enscript-type">class</span>. Force initialization of superclasses first.
 *
 * Called only from _class_lookupMethodAndLoadCache (<span class="enscript-type">or</span> itself).
 *
 * #ifdef OBJC_COLLECTING_CACHE
 *    The messageLock can be in either state.
 * #<span class="enscript-keyword">else</span>
 *    The messageLock is already assumed to be taken out.
 *    It is temporarily released <span class="enscript-keyword">while</span> the initialize method is sent. 
 * #endif
 **********************************************************************/
static void	class_initialize	       (Class		clsDesc)
{
	struct objc_class *	super;

	// Skip <span class="enscript-keyword">if</span> someone <span class="enscript-keyword">else</span> beat us to it
	<span class="enscript-keyword">if</span> (ISINITIALIZED(((struct objc_class *)clsDesc)))
		<span class="enscript-keyword">return</span>;

	// Force initialization of superclasses first
	super = ((struct objc_class *)clsDesc)-&gt;super_class;
	<span class="enscript-keyword">if</span> ((super != Nil) &amp;&amp; (!ISINITIALIZED(super)))
		class_initialize (super);

	// Initializing the super <span class="enscript-type">class</span> might have initialized us,
	// <span class="enscript-type">or</span> another thread might have initialized us during this time.
	<span class="enscript-keyword">if</span> (ISINITIALIZED(((struct objc_class *)clsDesc)))
		<span class="enscript-keyword">return</span>;

	// Mark the <span class="enscript-type">class</span> initialized so it can receive the &quot;initialize&quot;
	// message.  This solution to the <span class="enscript-type">catch</span>-22 is the source of a
	// bug: the <span class="enscript-type">class</span> is able to receive messages *from anyone* <span class="enscript-type">now</span>
	// that it is marked, even though initialization is <span class="enscript-type">not</span> complete.
	MARKINITIALIZED(((struct objc_class *)clsDesc));

#ifndef OBJC_COLLECTING_CACHE
	// Release the message lock so that messages can be sent.
	OBJC_UNLOCK(&amp;messageLock);
#endif

	// Send the initialize method.
	<span class="enscript-type">[</span>(id)clsDesc initialize<span class="enscript-type">]</span>;

#ifndef OBJC_COLLECTING_CACHE
	// Re-acquire the lock
	OBJC_LOCK(&amp;messageLock);
#endif

	<span class="enscript-keyword">return</span>;
}

/***********************************************************************
 * _class_install_relationships.  Fill in the <span class="enscript-type">class</span> pointers of a <span class="enscript-type">class</span>
 * that was loaded before some <span class="enscript-type">or</span> <span class="enscript-type">all</span> of the classes it needs to point to.
 * The <span class="enscript-type">deal</span> here is that the <span class="enscript-type">class</span> pointer fields have been usurped to
 * <span class="enscript-type">hold</span> the string name of the pertinent <span class="enscript-type">class</span>.  Our job is to look up
 * the <span class="enscript-type">real</span> thing based on those stored names.
 **********************************************************************/
void	_class_install_relationships	       (Class	cls,
						long	<span class="enscript-type">version</span>)
{
	struct objc_class *		meta;
	struct objc_class *		clstmp;

	// Get easy access to meta <span class="enscript-type">class</span> structure
	meta = ((struct objc_class *)cls)-&gt;<span class="enscript-type">isa</span>;
	
	// Set <span class="enscript-type">version</span> in meta <span class="enscript-type">class</span> strucure
	meta-&gt;<span class="enscript-type">version</span> = <span class="enscript-type">version</span>;

	// Install superclass based on stored name.  No name iff
	// cls is a root <span class="enscript-type">class</span>.
	<span class="enscript-keyword">if</span> (((struct objc_class *)cls)-&gt;super_class)
	{
		clstmp = objc_getClass ((const <span class="enscript-type">char</span> *) ((struct objc_class *)cls)-&gt;super_class);
		<span class="enscript-keyword">if</span> (!clstmp)
		{
			_objc_inform(&quot;failed objc_getClass(<span class="enscript-comment">%s) for %s-&gt;super_class&quot;, (const char *)((struct objc_class *)cls)-&gt;super_class, ((struct objc_class *)cls)-&gt;name);
</span>			goto Error;
		}
		
		((struct objc_class *)cls)-&gt;super_class = clstmp;
	}

	// Install meta<span class="enscript-keyword">'</span>s <span class="enscript-type">isa</span> based on stored name.  Meta <span class="enscript-type">class</span> <span class="enscript-type">isa</span>
	// pointers always point to the meta <span class="enscript-type">class</span> of the root <span class="enscript-type">class</span>
	// (root meta <span class="enscript-type">class</span>, too, it points to itself!).
	clstmp = objc_getClass ((const <span class="enscript-type">char</span> *) meta-&gt;<span class="enscript-type">isa</span>);
	<span class="enscript-keyword">if</span> (!clstmp)
	{
		_objc_inform(&quot;failed objc_getClass(<span class="enscript-comment">%s) for %s-&gt;isa-&gt;isa&quot;, (const char *) meta-&gt;isa, ((struct objc_class *)cls)-&gt;name);
</span>		goto Error;
	}
	
	meta-&gt;<span class="enscript-type">isa</span> = clstmp-&gt;<span class="enscript-type">isa</span>;

	// Install meta<span class="enscript-keyword">'</span>s superclass based on stored name.  No name iff
	// cls is a root <span class="enscript-type">class</span>.
	<span class="enscript-keyword">if</span> (meta-&gt;super_class)
	{
		// Locate instance <span class="enscript-type">class</span> of super <span class="enscript-type">class</span>
		clstmp = objc_getClass ((const <span class="enscript-type">char</span> *) meta-&gt;super_class);
		<span class="enscript-keyword">if</span> (!clstmp)
		{
			_objc_inform(&quot;failed objc_getClass(<span class="enscript-comment">%s) for %s-&gt;isa-&gt;super_class&quot;, (const char *)meta-&gt;super_class, ((struct objc_class *)cls)-&gt;name);
</span>			goto Error;
		}
		
		// Store meta <span class="enscript-type">class</span> of super <span class="enscript-type">class</span>
		meta-&gt;super_class = clstmp-&gt;<span class="enscript-type">isa</span>;
	}

	// cls is root, so `tie<span class="enscript-keyword">'</span> the (root) meta <span class="enscript-type">class</span> down to its
	// instance <span class="enscript-type">class</span>.  This way, <span class="enscript-type">class</span> methods can come from
	// the root instance <span class="enscript-type">class</span>.
	<span class="enscript-keyword">else</span>
		((struct objc_class *)meta)-&gt;super_class = cls;

	// Use common static empty cache instead of NULL
	<span class="enscript-keyword">if</span> (((struct objc_class *)cls)-&gt;cache == NULL)
		((struct objc_class *)cls)-&gt;cache = (Cache) &amp;emptyCache;
	<span class="enscript-keyword">if</span> (((struct objc_class *)meta)-&gt;cache == NULL)
		((struct objc_class *)meta)-&gt;cache = (Cache) &amp;emptyCache;

	<span class="enscript-keyword">return</span>;

Error:
	_objc_fatal (&quot;please link appropriate classes in your program&quot;);
}

/***********************************************************************
 * objc_malloc.
 **********************************************************************/
static void *		objc_malloc		   (int		byteCount)
{
	void *		space;

	space = malloc_zone_malloc (_objc_create_zone (), byteCount);
	<span class="enscript-keyword">if</span> (!space &amp;&amp; byteCount)
		_objc_fatal (&quot;unable to allocate space&quot;);

#ifdef WIN32
	bzero (space, byteCount);
#endif

	<span class="enscript-keyword">return</span> space;
}


/***********************************************************************
 * class_respondsToMethod.
 *
 * Called from -<span class="enscript-type">[</span>Object respondsTo:<span class="enscript-type">]</span> <span class="enscript-type">and</span> +<span class="enscript-type">[</span>Object instancesRespondTo:<span class="enscript-type">]</span>
 **********************************************************************/
BOOL	class_respondsToMethod	       (Class		cls,
					SEL		sel)
{
	struct objc_class *				thisCls;
	arith_t				index;
	arith_t				mask;
	Method *			buckets;
	Method				meth;
	
	// No one responds to zero!
	<span class="enscript-keyword">if</span> (!sel) 
		<span class="enscript-keyword">return</span> NO;

	// Synchronize access to caches
	OBJC_LOCK(&amp;messageLock);

	// Look in the cache of the specified <span class="enscript-type">class</span>
	mask	= ((struct objc_class *)cls)-&gt;cache-&gt;mask;
	buckets	= ((struct objc_class *)cls)-&gt;cache-&gt;buckets;
	index	= ((uarith_t) sel &amp; mask);
	<span class="enscript-keyword">while</span> (CACHE_BUCKET_VALID(buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>)) {
		<span class="enscript-keyword">if</span> (CACHE_BUCKET_NAME(buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) == sel) {
			<span class="enscript-keyword">if</span> (CACHE_BUCKET_IMP(buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) == &amp;_objc_msgForward) {
				OBJC_UNLOCK(&amp;messageLock);
				<span class="enscript-keyword">return</span> NO;
			} <span class="enscript-keyword">else</span> {
				OBJC_UNLOCK(&amp;messageLock);
				<span class="enscript-keyword">return</span> YES;
			}
		}
		
		index += 1;
		index &amp;= mask;
	}

	// Handle cache miss
	meth = _getMethod(cls, sel);
	<span class="enscript-keyword">if</span> (meth) {
		OBJC_UNLOCK(&amp;messageLock);
		_cache_fill (cls, meth, sel);
		<span class="enscript-keyword">return</span> YES;
	}
	
	// Not implememted.  Use _objc_msgForward.
	{
	Method	smt;

	smt = malloc_zone_malloc (_objc_create_zone(), sizeof(struct objc_method));
	smt-&gt;method_name	= sel;
	smt-&gt;method_types	= &quot;&quot;;
	smt-&gt;method_imp		= &amp;_objc_msgForward;
	_cache_fill (cls, smt, sel);
	}

	OBJC_UNLOCK(&amp;messageLock);
	<span class="enscript-keyword">return</span> NO;

}


/***********************************************************************
 * class_lookupMethod.
 *
 * Called from -<span class="enscript-type">[</span>Object methodFor:<span class="enscript-type">]</span> <span class="enscript-type">and</span> +<span class="enscript-type">[</span>Object instanceMethodFor:<span class="enscript-type">]</span>
 **********************************************************************/

IMP		class_lookupMethod	       (Class		cls,
						SEL		sel)
{
	Method *	buckets;
	arith_t		index;
	arith_t		mask;
	IMP		result;
	
	// No one responds to zero!
	<span class="enscript-keyword">if</span> (!sel) 
		<span class="enscript-type">[</span>(id) cls <span class="enscript-keyword">error</span>:_errBadSel, sel<span class="enscript-type">]</span>;

	// Synchronize access to caches
	OBJC_LOCK(&amp;messageLock);

	// Scan the cache
	mask	= ((struct objc_class *)cls)-&gt;cache-&gt;mask;
	buckets	= ((struct objc_class *)cls)-&gt;cache-&gt;buckets;
	index	= ((unsigned int) sel &amp; mask);
	<span class="enscript-keyword">while</span> (CACHE_BUCKET_VALID(buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>))
	{
		<span class="enscript-keyword">if</span> (CACHE_BUCKET_NAME(buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) == sel)
		{
			result = CACHE_BUCKET_IMP(buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>);
			OBJC_UNLOCK(&amp;messageLock);
			<span class="enscript-keyword">return</span> result;
		}
		
		index += 1;
		index &amp;= mask;
	}

	// Handle cache miss
	result = _class_lookupMethodAndLoadCache (cls, sel);
	OBJC_UNLOCK(&amp;messageLock);
	<span class="enscript-keyword">return</span> result;
}

/***********************************************************************
 * class_lookupMethodInMethodList.
 *
 * Called from objc-<span class="enscript-type">load</span>.m <span class="enscript-type">and</span> _objc_callLoads ()
 **********************************************************************/
IMP	class_lookupMethodInMethodList (struct objc_method_list *	mlist,
					SEL				sel)
{
    Method m = _findMethodInList(mlist, sel);
    <span class="enscript-keyword">return</span> (m ? m-&gt;method_imp : NULL);
}

IMP	class_lookupNamedMethodInMethodList(struct objc_method_list *mlist,
					const <span class="enscript-type">char</span> *meth_name)
{
    Method m = meth_name ? _findNamedMethodInList(mlist, meth_name) : NULL;
    <span class="enscript-keyword">return</span> (m ? m-&gt;method_imp : NULL);
}

/***********************************************************************
 * _cache_create.
 *
 * Called from _cache_expand () <span class="enscript-type">and</span> objc_addClass ()
 **********************************************************************/
Cache		_cache_create		(Class		cls)
{
	Cache		new_cache;
	int			slotCount;
	int			index;

	// Select appropriate <span class="enscript-type">size</span>
	slotCount = (ISMETA(cls)) ? INIT_META_CACHE_SIZE : INIT_CACHE_SIZE;

	// Allocate table (why <span class="enscript-type">not</span> check <span class="enscript-keyword">for</span> failure?)
#ifdef OBJC_INSTRUMENTED
	new_cache = malloc_zone_malloc (_objc_create_zone(),
			sizeof(struct objc_cache) + TABLE_SIZE(slotCount)
			 + sizeof(CacheInstrumentation));
#<span class="enscript-keyword">else</span>
	new_cache = malloc_zone_malloc (_objc_create_zone(),
			sizeof(struct objc_cache) + TABLE_SIZE(slotCount));
#endif

	// Invalidate <span class="enscript-type">all</span> the buckets
	<span class="enscript-keyword">for</span> (index = 0; index &lt; slotCount; index += 1)
		CACHE_BUCKET_VALID(new_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) = NULL;
	
	// Zero the valid-entry counter
	new_cache-&gt;occupied = 0;
	
	// Set the mask so indexing wraps at the <span class="enscript-keyword">end</span>-of-table
	new_cache-&gt;mask = slotCount - 1;

#ifdef OBJC_INSTRUMENTED
	{
	CacheInstrumentation *	cacheData;

	// Zero out the cache dynamic instrumention data
	cacheData = CACHE_INSTRUMENTATION(new_cache);
	bzero ((<span class="enscript-type">char</span> *) cacheData, sizeof(CacheInstrumentation));
	}
#endif

	// Install the cache
	((struct objc_class *)cls)-&gt;cache = new_cache;

	// Clear the cache flush flag so that we will <span class="enscript-type">not</span> flush this cache
	// before expanding it <span class="enscript-keyword">for</span> the first time.
	((struct objc_class * )cls)-&gt;info &amp;= ~(CLS_FLUSH_CACHE);

	// Clear the grow flag so that we will re-use the current storage,
	// rather than actually grow the cache, when expanding the cache
	// <span class="enscript-keyword">for</span> the first time
	<span class="enscript-keyword">if</span> (_class_slow_grow)
		((struct objc_class * )cls)-&gt;info &amp;= ~(CLS_GROW_CACHE);

	// Return our creation
	<span class="enscript-keyword">return</span> new_cache;
}

/***********************************************************************
 * _cache_expand.
 *
 * #ifdef OBJC_COLLECTING_CACHE
 *	The cacheUpdateLock is assumed to be taken at this point. 
 * #endif
 *
 * Called from _cache_fill ()
 **********************************************************************/
static	Cache		_cache_expand	       (Class		cls)
{
	Cache		old_cache;
	Cache		new_cache;
	unsigned int	slotCount;
	unsigned int	index;

	// First growth goes from emptyCache to a <span class="enscript-type">real</span> one
	old_cache = ((struct objc_class *)cls)-&gt;cache;
	<span class="enscript-keyword">if</span> (old_cache == &amp;emptyCache)
		<span class="enscript-keyword">return</span> _cache_create (cls);

	// iff _class_slow_grow, trade off actual cache growth with re-using
	// the current one, so that growth only happens every odd time
	<span class="enscript-keyword">if</span> (_class_slow_grow)
	{
		// CLS_GROW_CACHE controls every-other-time behavior.  If it
		// is non-zero, let the cache grow this time, but <span class="enscript-keyword">clear</span> the
		// flag so the cache is reused next time
		<span class="enscript-keyword">if</span> ((((struct objc_class * )cls)-&gt;info &amp; CLS_GROW_CACHE) != 0)
			((struct objc_class * )cls)-&gt;info &amp;= ~CLS_GROW_CACHE;

		// Reuse the current cache storage this time
		<span class="enscript-keyword">else</span>
		{
			// Clear the valid-entry counter
			old_cache-&gt;occupied = 0;

			// Invalidate <span class="enscript-type">all</span> the cache entries
			<span class="enscript-keyword">for</span> (index = 0; index &lt; old_cache-&gt;mask + 1; index += 1)
			{
				// Remember <span class="enscript-type">what</span> this entry was, so we can possibly
				// deallocate it after the bucket has been invalidated
				Method		oldEntry = old_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
				// Skip invalid entry
				<span class="enscript-keyword">if</span> (!CACHE_BUCKET_VALID(old_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>))
					continue;

				// Invalidate this entry
				CACHE_BUCKET_VALID(old_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) = NULL;
					
				// Deallocate &quot;forward::&quot; entry
				<span class="enscript-keyword">if</span> (CACHE_BUCKET_IMP(oldEntry) == &amp;_objc_msgForward)
				{
#ifdef OBJC_COLLECTING_CACHE
					_cache_collect_free (oldEntry, NO);
#<span class="enscript-keyword">else</span>
					malloc_zone_free (_objc_create_zone(), oldEntry);
#endif
				}
			}
			
			// Set the slow growth flag so the cache is next grown
			((struct objc_class * )cls)-&gt;info |= CLS_GROW_CACHE;
			
			// Return the same old cache, freshly emptied
			<span class="enscript-keyword">return</span> old_cache;
		}
		
	}

	// Double the cache <span class="enscript-type">size</span>
	slotCount = (old_cache-&gt;mask + 1) &lt;&lt; 1;
	
	// Allocate a new cache table
#ifdef OBJC_INSTRUMENTED
	new_cache = malloc_zone_malloc (_objc_create_zone(),
			sizeof(struct objc_cache) + TABLE_SIZE(slotCount)
			 + sizeof(CacheInstrumentation));
#<span class="enscript-keyword">else</span>
	new_cache = malloc_zone_malloc (_objc_create_zone(),
			sizeof(struct objc_cache) + TABLE_SIZE(slotCount));
#endif

	// Zero out the new cache
	new_cache-&gt;mask = slotCount - 1;
	new_cache-&gt;occupied = 0;
	<span class="enscript-keyword">for</span> (index = 0; index &lt; slotCount; index += 1)
		CACHE_BUCKET_VALID(new_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) = NULL;

#ifdef OBJC_INSTRUMENTED
	// Propagate the instrumentation data
	{
	CacheInstrumentation *	oldCacheData;
	CacheInstrumentation *	newCacheData;

	oldCacheData = CACHE_INSTRUMENTATION(old_cache);
	newCacheData = CACHE_INSTRUMENTATION(new_cache);
	bcopy ((const <span class="enscript-type">char</span> *)oldCacheData, (<span class="enscript-type">char</span> *)newCacheData, sizeof(CacheInstrumentation));
	}
#endif

	// iff _class_uncache, copy old cache entries into the new cache
	<span class="enscript-keyword">if</span> (_class_uncache == 0)
	{
		int	newMask;
		
		newMask = new_cache-&gt;mask;
		
		// Look at <span class="enscript-type">all</span> entries in the old cache
		<span class="enscript-keyword">for</span> (index = 0; index &lt; old_cache-&gt;mask + 1; index += 1)
		{
			int	index2;

			// Skip invalid entry
			<span class="enscript-keyword">if</span> (!CACHE_BUCKET_VALID(old_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>))
				continue;
			
			// Hash the old entry into the new table
			index2 = ((unsigned int) CACHE_BUCKET_NAME(old_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) &amp; newMask);
			
			// Find an available spot, at <span class="enscript-type">or</span> following the hashed spot;
			// Guaranteed to <span class="enscript-type">not</span> infinite loop, because table has grown
			<span class="enscript-keyword">for</span> (;;)
			{
				<span class="enscript-keyword">if</span> (!CACHE_BUCKET_VALID(new_cache-&gt;buckets<span class="enscript-type">[</span>index2<span class="enscript-type">]</span>))
				{
					new_cache-&gt;buckets<span class="enscript-type">[</span>index2<span class="enscript-type">]</span> = old_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
					<span class="enscript-keyword">break</span>;
				}
					
				index2 += 1;
				index2 &amp;= newMask;
			}

			// Account <span class="enscript-keyword">for</span> the addition
			new_cache-&gt;occupied += 1;
		}
	
		// Set the cache flush flag so that we will flush this cache
		// before expanding it again.
		((struct objc_class * )cls)-&gt;info |= CLS_FLUSH_CACHE;
	}

	// Deallocate &quot;forward::&quot; entries from the old cache
	<span class="enscript-keyword">else</span>
	{
		<span class="enscript-keyword">for</span> (index = 0; index &lt; old_cache-&gt;mask + 1; index += 1)
		{
			<span class="enscript-keyword">if</span> (CACHE_BUCKET_VALID(old_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) &amp;&amp;
				CACHE_BUCKET_IMP(old_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) == &amp;_objc_msgForward)
			{
#ifdef OBJC_COLLECTING_CACHE
				_cache_collect_free (old_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>, NO);
#<span class="enscript-keyword">else</span>
				malloc_zone_free (_objc_create_zone(), old_cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>);
#endif
			}
		}
	}

	// Install new cache
	((struct objc_class *)cls)-&gt;cache = new_cache;

	// Deallocate old cache, <span class="enscript-type">try</span> freeing <span class="enscript-type">all</span> the garbage
#ifdef OBJC_COLLECTING_CACHE
	_cache_collect_free (old_cache, YES);
#<span class="enscript-keyword">else</span>
	malloc_zone_free (_objc_create_zone(), old_cache);
#endif
	<span class="enscript-keyword">return</span> new_cache;
}

/***********************************************************************
 * instrumentObjcMessageSends/logObjcMessageSends.
 **********************************************************************/
static int	LogObjCMessageSend (BOOL			isClassMethod,
								const <span class="enscript-type">char</span> *	objectsClass,
								const <span class="enscript-type">char</span> *	implementingClass,
								SEL				selector)
{
	<span class="enscript-type">char</span>	buf<span class="enscript-type">[</span> 1024 <span class="enscript-type">]</span>;

	// Create/open the <span class="enscript-type">log</span> file	
	<span class="enscript-keyword">if</span> (objcMsgLogFD == (-1))
	{
		<span class="enscript-type">sprintf</span> (buf, &quot;/tmp/msgSends-<span class="enscript-comment">%d&quot;, (int) getpid ());
</span>		objcMsgLogFD = open (buf, O_WRONLY | O_CREAT, 0666);
	}

	// Make the <span class="enscript-type">log</span> entry
	<span class="enscript-type">sprintf</span>(buf, &quot;<span class="enscript-comment">%c %s %s %s\n&quot;,
</span>		isClassMethod ? <span class="enscript-string">'+'</span> : <span class="enscript-string">'-'</span>,
		objectsClass,
		implementingClass,
		(<span class="enscript-type">char</span> *) selector);
	
	write (objcMsgLogFD, buf, strlen(buf));

	// Tell caller to <span class="enscript-type">not</span> cache the method
	<span class="enscript-keyword">return</span> 0;
}

void	instrumentObjcMessageSends       (BOOL		flag)
{
	int		enabledValue = (flag) ? 1 : 0;

	// Shortcut NOP
	<span class="enscript-keyword">if</span> (objcMsgLogEnabled == enabledValue)
		<span class="enscript-keyword">return</span>;
	
	// If enabling, flush <span class="enscript-type">all</span> method caches so we <span class="enscript-type">get</span> some traces
	<span class="enscript-keyword">if</span> (flag)
		flush_caches (Nil, YES);
	
	// Sync our <span class="enscript-type">log</span> file
	<span class="enscript-keyword">if</span> (objcMsgLogFD != (-1))
		fsync (objcMsgLogFD);

	objcMsgLogEnabled = enabledValue;
}

void	logObjcMessageSends      (ObjCLogProc	logProc)
{
	<span class="enscript-keyword">if</span> (logProc)
	{
		objcMsgLogProc = logProc;
		objcMsgLogEnabled = 1;
	}
	<span class="enscript-keyword">else</span>
	{
		objcMsgLogProc = logProc;
		objcMsgLogEnabled = 0;
	}

	<span class="enscript-keyword">if</span> (objcMsgLogFD != (-1))
		fsync (objcMsgLogFD);
}

/***********************************************************************
 * _cache_fill.  Add the specified method to the specified class<span class="enscript-keyword">'</span> cache.
 *
 * Called only from _class_lookupMethodAndLoadCache <span class="enscript-type">and</span>
 * class_respondsToMethod.
 *
 * #ifdef OBJC_COLLECTING_CACHE
 *	It doesn<span class="enscript-keyword">'</span>t matter <span class="enscript-keyword">if</span> someone has the messageLock when we enter this
 *	<span class="enscript-keyword">function</span>.  This <span class="enscript-keyword">function</span> will fail to do the update <span class="enscript-keyword">if</span> someone <span class="enscript-keyword">else</span>
 *	is already updating the cache, <span class="enscript-type">i</span>.e. they have the cacheUpdateLock.
 * #<span class="enscript-keyword">else</span>
 *	The messageLock is already assumed to be taken out.
 * #endif
 **********************************************************************/

static	void	_cache_fill    (Class		cls,
								Method		smt,
								SEL			sel)
{
	Cache				cache;
	Method *			buckets;

	arith_t				index;
	arith_t				mask;
	unsigned int		newOccupied;

	// Keep tally of cache additions
	totalCacheFills += 1;

#ifdef OBJC_COLLECTING_CACHE
	// Make sure only one thread is updating the cache at a time, but don<span class="enscript-keyword">'</span>t
	// wait <span class="enscript-keyword">for</span> concurrent updater to finish, because it might be a <span class="enscript-keyword">while</span>, <span class="enscript-type">or</span>
	// a deadlock!  Instead, just leave the method out of the cache until
	// next time.  This is nasty given that cacheUpdateLock is per task!
	<span class="enscript-keyword">if</span> (!OBJC_TRYLOCK(&amp;cacheUpdateLock))
		<span class="enscript-keyword">return</span>;

	// Set up invariants <span class="enscript-keyword">for</span> cache traversals
	cache	= ((struct objc_class *)cls)-&gt;cache;
	mask	= cache-&gt;mask;
	buckets	= cache-&gt;buckets;

	// Check <span class="enscript-keyword">for</span> duplicate entries, <span class="enscript-keyword">if</span> we<span class="enscript-keyword">'</span>re in the mode
	<span class="enscript-keyword">if</span> (traceDuplicates)
	{
		int	index2;
		
		// Scan the cache
		<span class="enscript-keyword">for</span> (index2 = 0; index2 &lt; mask + 1; index2 += 1)
		{
			// Skip invalid <span class="enscript-type">or</span> non-duplicate entry
			<span class="enscript-keyword">if</span> ((!CACHE_BUCKET_VALID(buckets<span class="enscript-type">[</span>index2<span class="enscript-type">]</span>)) ||
			    (<span class="enscript-type">strcmp</span> ((<span class="enscript-type">char</span> *) CACHE_BUCKET_NAME(buckets<span class="enscript-type">[</span>index2<span class="enscript-type">]</span>), (<span class="enscript-type">char</span> *) smt-&gt;method_name) != 0))
				continue;

			// Tally duplication, but report iff wanted
			cacheFillDuplicates += 1;
			<span class="enscript-keyword">if</span> (traceDuplicatesVerbose)
			{
				_objc_inform  (&quot;Cache <span class="enscript-type">fill</span> duplicate #<span class="enscript-comment">%d: found %x adding %x: %s\n&quot;,
</span>								cacheFillDuplicates,
								(unsigned int) CACHE_BUCKET_NAME(buckets<span class="enscript-type">[</span>index2<span class="enscript-type">]</span>),
								(unsigned int) smt-&gt;method_name,
								(<span class="enscript-type">char</span> *) smt-&gt;method_name);
			}
		}
	}

	// Do nothing <span class="enscript-keyword">if</span> entry is already placed.  This re-check is needed
	// only in the OBJC_COLLECTING_CACHE code, because the probe is
	// done un-sync<span class="enscript-keyword">'</span>d.
	index	= ((unsigned int) sel &amp; mask);
	<span class="enscript-keyword">while</span> (CACHE_BUCKET_VALID(buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>))
	{
		<span class="enscript-keyword">if</span> (CACHE_BUCKET_NAME(buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) == sel)
		{
			OBJC_UNLOCK(&amp;cacheUpdateLock);
			<span class="enscript-keyword">return</span>;
		}
		
		index += 1;
		index &amp;= mask;
	}

#<span class="enscript-keyword">else</span> // <span class="enscript-type">not</span> OBJC_COLLECTING_CACHE
	cache	= ((struct objc_class *)cls)-&gt;cache;
	mask	= cache-&gt;mask;
#endif

	// Use the cache as-is <span class="enscript-keyword">if</span> it is less than 3/4 <span class="enscript-type">full</span>
	newOccupied = cache-&gt;occupied + 1;
	<span class="enscript-keyword">if</span> ((newOccupied * 4) &lt;= (mask + 1) * 3)
		cache-&gt;occupied = newOccupied;
	
	// Cache is getting <span class="enscript-type">full</span>
	<span class="enscript-keyword">else</span>
	{
		// Flush the cache
		<span class="enscript-keyword">if</span> ((((struct objc_class * )cls)-&gt;info &amp; CLS_FLUSH_CACHE) != 0)
			_cache_flush (cls);
		
		// Expand the cache
		<span class="enscript-keyword">else</span>
		{
			cache = _cache_expand (cls);
			mask  = cache-&gt;mask;
		}
		
		// Account <span class="enscript-keyword">for</span> the addition
		cache-&gt;occupied += 1;
	}
	
	// Insert the new entry.  This can be done by either:
	// 	(a) Scanning <span class="enscript-keyword">for</span> the first unused spot.  Easy!
	//	(b) Opening up an unused spot by sliding existing
	//	    entries down by one.  The benefit of this
	//	    extra work is that it puts the most recently
	//	    loaded entries closest to where the selector
	//	    hash starts the search.
	//
	// The loop is a little <span class="enscript-type">more</span> complicated because there
	// are two kinds of entries, so there have to be two ways
	// to slide them.
	buckets	= cache-&gt;buckets;
	index	= ((unsigned int) sel &amp; mask);
	<span class="enscript-keyword">for</span> (;;)
	{
		// Slide existing entries down by one
		Method		saveMethod;
		
		// Copy current entry to a local
		saveMethod = buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
		
		// Copy previous entry (<span class="enscript-type">or</span> new entry) to current slot
		buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span> = smt;
		
		// Done <span class="enscript-keyword">if</span> current slot had been invalid
		<span class="enscript-keyword">if</span> (saveMethod == NULL)
			<span class="enscript-keyword">break</span>;
		
		// Prepare to copy saved value into next slot
		smt = saveMethod;

		// Move on to next slot
		index += 1;
		index &amp;= mask;
	}

#ifdef OBJC_COLLECTING_CACHE
	OBJC_UNLOCK(&amp;cacheUpdateLock);
#endif
}

/***********************************************************************
 * _cache_flush.  Invalidate <span class="enscript-type">all</span> valid entries in the given class<span class="enscript-keyword">'</span> cache,
 * <span class="enscript-type">and</span> <span class="enscript-keyword">clear</span> the CLS_FLUSH_CACHE in the cls-&gt;info.
 *
 * Called from flush_caches ().
 **********************************************************************/
static void	_cache_flush		(Class		cls)
{
	Cache			cache;
	unsigned int	index;
	
	// Locate cache.  Ignore unused cache.
	cache = ((struct objc_class *)cls)-&gt;cache;
	<span class="enscript-keyword">if</span> (cache == &amp;emptyCache)
		<span class="enscript-keyword">return</span>;

#ifdef OBJC_INSTRUMENTED
	{
	CacheInstrumentation *	cacheData;

	// Tally this flush
	cacheData = CACHE_INSTRUMENTATION(cache);
	cacheData-&gt;flushCount += 1;
	cacheData-&gt;flushedEntries += cache-&gt;occupied;
	<span class="enscript-keyword">if</span> (cache-&gt;occupied &gt; cacheData-&gt;maxFlushedEntries)
		cacheData-&gt;maxFlushedEntries = cache-&gt;occupied;
	}
#endif
	
	// Traverse the cache
	<span class="enscript-keyword">for</span> (index = 0; index &lt;= cache-&gt;mask; index += 1)
	{
		// Remember <span class="enscript-type">what</span> this entry was, so we can possibly
		// deallocate it after the bucket has been invalidated
		Method		oldEntry = cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>;

		// Invalidate this entry
		CACHE_BUCKET_VALID(cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) = NULL;

		// Deallocate &quot;forward::&quot; entry
		<span class="enscript-keyword">if</span> (oldEntry &amp;&amp; oldEntry-&gt;method_imp == &amp;_objc_msgForward)
#ifdef OBJC_COLLECTING_CACHE
			_cache_collect_free (oldEntry, NO);
#<span class="enscript-keyword">else</span>
			malloc_zone_free (_objc_create_zone(), oldEntry);
#endif
	}
	
	// Clear the valid-entry counter
	cache-&gt;occupied = 0;

	// Clear the cache flush flag so that we will <span class="enscript-type">not</span> flush this cache
	// before expanding it again.
	((struct objc_class * )cls)-&gt;info &amp;= ~CLS_FLUSH_CACHE;
}

/***********************************************************************
 * _objc_getFreedObjectClass.  Return a pointer to the dummy freed
 * object <span class="enscript-type">class</span>.  Freed objects <span class="enscript-type">get</span> their <span class="enscript-type">isa</span> pointers replaced with
 * a pointer to the freedObjectClass, so that we can <span class="enscript-type">catch</span> usages of
 * the freed object.
 **********************************************************************/
Class		_objc_getFreedObjectClass	   (void)
{
	<span class="enscript-keyword">return</span> (Class) &amp;freedObjectClass;
}

/***********************************************************************
 * _objc_getNonexistentClass.  Return a pointer to the dummy nonexistent
 * object <span class="enscript-type">class</span>.  This is used when, <span class="enscript-keyword">for</span> example, mapping the <span class="enscript-type">class</span>
 * refs <span class="enscript-keyword">for</span> an <span class="enscript-type">image</span>, <span class="enscript-type">and</span> the <span class="enscript-type">class</span> can <span class="enscript-type">not</span> be found, so that we can
 * <span class="enscript-type">catch</span> later uses of the non-existent <span class="enscript-type">class</span>.
 **********************************************************************/
Class		_objc_getNonexistentClass	   (void)
{
	<span class="enscript-keyword">return</span> (Class) &amp;nonexistentObjectClass;
}

/***********************************************************************
 * _class_lookupMethodAndLoadCache.
 *
 * Called only from objc_msgSend, objc_msgSendSuper <span class="enscript-type">and</span> class_lookupMethod.
 **********************************************************************/
IMP	_class_lookupMethodAndLoadCache	   (Class	cls,
										SEL		sel)
{
	struct objc_class *	curClass;
	Method	smt;
	BOOL	calledSingleThreaded;
	IMP		methodPC;

	ptrace(0xb300, 0, 0, 0);
	
	// Check <span class="enscript-keyword">for</span> freed <span class="enscript-type">class</span>
	<span class="enscript-keyword">if</span> (cls == &amp;freedObjectClass)
		<span class="enscript-keyword">return</span> (IMP) _freedHandler;
	
	// Check <span class="enscript-keyword">for</span> nonexistent <span class="enscript-type">class</span>
	<span class="enscript-keyword">if</span> (cls == &amp;nonexistentObjectClass)
		<span class="enscript-keyword">return</span> (IMP) _nonexistentHandler;
	
#ifndef OBJC_COLLECTING_CACHE
	// Control can <span class="enscript-type">get</span> here via the single-threaded message dispatcher,
	// but class_initialize can cause application to go multithreaded.  Notice 
	// whether this is the <span class="enscript-type">case</span>, so we can leave the messageLock unlocked
	// on the way out, just as the single-threaded message dispatcher
	// expects.  Note that the messageLock locking in classinitialize is
	// appropriate in this <span class="enscript-type">case</span>, because there are <span class="enscript-type">more</span> than one thread <span class="enscript-type">now</span>.
	calledSingleThreaded = (_objc_multithread_mask != 0);
#endif

	ptrace(0xb301, 0, 0, 0);
	
	// Lazy initialization.  This unlocks <span class="enscript-type">and</span> relocks messageLock,
	// so cache information we might already have becomes invalid.
	<span class="enscript-keyword">if</span> (!ISINITIALIZED(cls))
		class_initialize (objc_getClass (((struct objc_class *)cls)-&gt;name));
	
	ptrace(0xb302, 0, 0, 0);

	// Outer loop - search the caches <span class="enscript-type">and</span> method lists of the
	// <span class="enscript-type">class</span> <span class="enscript-type">and</span> its super-classes
	methodPC = NULL;
	<span class="enscript-keyword">for</span> (curClass = cls; curClass; curClass = ((struct objc_class * )curClass)-&gt;super_class)
	{
		Method *					buckets;
		arith_t						idx;
		arith_t						mask;
		arith_t						methodCount;
		struct objc_method_list *mlist;
		void *iterator = 0;
#ifdef PRELOAD_SUPERCLASS_CACHES
		struct objc_class *						curClass2;
#endif

		ptrace(0xb303, 0, 0, 0);
	
		mask    = curClass-&gt;cache-&gt;mask;
		buckets	= curClass-&gt;cache-&gt;buckets;

		// Minor loop #1 - check cache of given <span class="enscript-type">class</span>
		<span class="enscript-keyword">for</span> (idx = ((uarith_t) sel &amp; mask);
			 CACHE_BUCKET_VALID(buckets<span class="enscript-type">[</span>idx<span class="enscript-type">]</span>);
			 idx = (++idx &amp; mask))
		{
			// Skip entries until selector matches
			<span class="enscript-keyword">if</span> (CACHE_BUCKET_NAME(buckets<span class="enscript-type">[</span>idx<span class="enscript-type">]</span>) != sel)
				continue;

			// Found the method.  Add it to the cache(s)
			// unless it was found in the cache of the
			// <span class="enscript-type">class</span> originally being messaged.
			//
			// NOTE: The method is usually <span class="enscript-type">not</span> found
			// the original class<span class="enscript-keyword">'</span> cache, because
			// objc_msgSend () has already looked.
			// BUT, <span class="enscript-keyword">if</span> sending this method resulted in
			// a +initialize on the <span class="enscript-type">class</span>, <span class="enscript-type">and</span> +initialize
			// sends the same method, the method will
			// indeed <span class="enscript-type">now</span> be in the cache.  Calling
			// _cache_fill with a buckets<span class="enscript-type">[</span>idx<span class="enscript-type">]</span> from the
			// cache being filled results in a crash
			// <span class="enscript-keyword">if</span> the cache has to grow, because the
			// buckets<span class="enscript-type">[</span>idx<span class="enscript-type">]</span> address is no longer valid. 
			<span class="enscript-keyword">if</span> (curClass != cls)
			{
#ifdef PRELOAD_SUPERCLASS_CACHES
				<span class="enscript-keyword">for</span> (curClass2 = cls; curClass2 != curClass; curClass2 = curClass2-&gt;super_class)
					_cache_fill (curClass2, buckets<span class="enscript-type">[</span>idx<span class="enscript-type">]</span>, sel);
				_cache_fill (curClass, buckets<span class="enscript-type">[</span>idx<span class="enscript-type">]</span>, sel);
#<span class="enscript-keyword">else</span>
				_cache_fill (cls, buckets<span class="enscript-type">[</span>idx<span class="enscript-type">]</span>, sel);
#endif
			}

			// Return the implementation address
			methodPC = CACHE_BUCKET_IMP(buckets<span class="enscript-type">[</span>idx<span class="enscript-type">]</span>);
			<span class="enscript-keyword">break</span>;
		}

		ptrace(0xb304, (int)methodPC, 0, 0);
	
		// Done <span class="enscript-keyword">if</span> that found it
		<span class="enscript-keyword">if</span> (methodPC)
			<span class="enscript-keyword">break</span>;

		smt = _findMethodInClass(curClass, sel);

		<span class="enscript-keyword">if</span> (smt) {
			// If logging is enabled, <span class="enscript-type">log</span> the message send <span class="enscript-type">and</span> let
			// the logger decide whether to encache the method.
			<span class="enscript-keyword">if</span> ((objcMsgLogEnabled == 0) ||
			(objcMsgLogProc (CLS_GETINFO(((struct objc_class * )curClass),CLS_META) ? YES : NO,
						((struct objc_class *)cls)-&gt;name,
						curClass-&gt;name, sel)))
			{
				// Cache the method implementation
#ifdef PRELOAD_SUPERCLASS_CACHES
				<span class="enscript-keyword">for</span> (curClass2 = cls; curClass2 != curClass; curClass2 = curClass2-&gt;super_class)
					_cache_fill (curClass2, smt, sel);
				_cache_fill (curClass, smt, sel);
#<span class="enscript-keyword">else</span>
				_cache_fill (cls, smt, sel);
#endif
			}
			// Return the implementation
			methodPC = smt-&gt;method_imp;
		}

		ptrace(0xb305, (int)methodPC, 0, 0);
	
		// Done <span class="enscript-keyword">if</span> that found it
		<span class="enscript-keyword">if</span> (methodPC)
			<span class="enscript-keyword">break</span>;
	}

	ptrace(0xb306, (int)methodPC, 0, 0);
	
	<span class="enscript-keyword">if</span> (methodPC == NULL)
	{
		// Class <span class="enscript-type">and</span> superclasses do <span class="enscript-type">not</span> respond -- use forwarding
		smt = malloc_zone_malloc (_objc_create_zone(), sizeof(struct objc_method));
		smt-&gt;method_name	= sel;
		smt-&gt;method_types	= &quot;&quot;;
		smt-&gt;method_imp		= &amp;_objc_msgForward;
		_cache_fill (cls, smt, sel);
		methodPC = &amp;_objc_msgForward;
	}
	
#ifndef OBJC_COLLECTING_CACHE
	// Unlock the lock
	<span class="enscript-keyword">if</span> (calledSingleThreaded)
		OBJC_UNLOCK(&amp;messageLock);
#endif

	ptrace(0xb30f, (int)methodPC, 0, 0);
	
	<span class="enscript-keyword">return</span> methodPC;
}

/***********************************************************************
 * SubtypeUntil.
 *
 * Delegation.
 **********************************************************************/
static int	SubtypeUntil	       (const <span class="enscript-type">char</span> *	<span class="enscript-type">type</span>,
					<span class="enscript-type">char</span>		<span class="enscript-keyword">end</span>) 
{
	int		level = 0;
	const <span class="enscript-type">char</span> *	head = <span class="enscript-type">type</span>;
	
	// 
	<span class="enscript-keyword">while</span> (*<span class="enscript-type">type</span>)
	{
		<span class="enscript-keyword">if</span> (!*<span class="enscript-type">type</span> || (!level &amp;&amp; (*<span class="enscript-type">type</span> == <span class="enscript-keyword">end</span>)))
			<span class="enscript-keyword">return</span> (int)(<span class="enscript-type">type</span> - head);
		
		<span class="enscript-keyword">switch</span> (*<span class="enscript-type">type</span>)
		{
			<span class="enscript-type">case</span> <span class="enscript-string">']'</span>: <span class="enscript-type">case</span> <span class="enscript-string">'}'</span>: <span class="enscript-type">case</span> <span class="enscript-string">')'</span>: level--; <span class="enscript-keyword">break</span>;
			<span class="enscript-type">case</span> <span class="enscript-string">'['</span>: <span class="enscript-type">case</span> <span class="enscript-string">'{'</span>: <span class="enscript-type">case</span> <span class="enscript-string">'('</span>: level += 1; <span class="enscript-keyword">break</span>;
		}
		
		<span class="enscript-type">type</span> += 1;
	}
	
	_objc_fatal (&quot;Object: SubtypeUntil: <span class="enscript-keyword">end</span> of <span class="enscript-type">type</span> encountered prematurely\n&quot;);
	<span class="enscript-keyword">return</span> 0;
}

/***********************************************************************
 * SkipFirstType.
 **********************************************************************/
static const <span class="enscript-type">char</span> *	SkipFirstType	   (const <span class="enscript-type">char</span> *	<span class="enscript-type">type</span>) 
{
	<span class="enscript-keyword">while</span> (1)
	{
		<span class="enscript-keyword">switch</span> (*<span class="enscript-type">type</span>++)
		{
			<span class="enscript-type">case</span> <span class="enscript-string">'O'</span>:	/* bycopy */
			<span class="enscript-type">case</span> <span class="enscript-string">'n'</span>:	/* in */
			<span class="enscript-type">case</span> <span class="enscript-string">'o'</span>:	/* out */
			<span class="enscript-type">case</span> <span class="enscript-string">'N'</span>:	/* inout */
			<span class="enscript-type">case</span> <span class="enscript-string">'r'</span>:	/* const */
			<span class="enscript-type">case</span> <span class="enscript-string">'V'</span>:	/* oneway */
			<span class="enscript-type">case</span> <span class="enscript-string">'^'</span>:	/* pointers */
				<span class="enscript-keyword">break</span>;
			
			/* arrays */
			<span class="enscript-type">case</span> <span class="enscript-string">'['</span>:
				<span class="enscript-keyword">while</span> ((*<span class="enscript-type">type</span> &gt;= <span class="enscript-string">'0'</span>) &amp;&amp; (*<span class="enscript-type">type</span> &lt;= <span class="enscript-string">'9'</span>))
					<span class="enscript-type">type</span> += 1;
				<span class="enscript-keyword">return</span> <span class="enscript-type">type</span> + SubtypeUntil (<span class="enscript-type">type</span>, <span class="enscript-string">']'</span>) + 1;
			
			/* structures */
			<span class="enscript-type">case</span> <span class="enscript-string">'{'</span>:
				<span class="enscript-keyword">return</span> <span class="enscript-type">type</span> + SubtypeUntil (<span class="enscript-type">type</span>, <span class="enscript-string">'}'</span>) + 1;
			
			/* unions */
			<span class="enscript-type">case</span> <span class="enscript-string">'('</span>:
				<span class="enscript-keyword">return</span> <span class="enscript-type">type</span> + SubtypeUntil (<span class="enscript-type">type</span>, <span class="enscript-string">')'</span>) + 1;
			
			/* basic types */
			default: 
				<span class="enscript-keyword">return</span> <span class="enscript-type">type</span>;
		}
	}
}

/***********************************************************************
 * method_getNumberOfArguments.
 **********************************************************************/
unsigned	method_getNumberOfArguments	   (Method	method)
{
	const <span class="enscript-type">char</span> *		typedesc;
	unsigned		nargs;
	
	// First, skip the <span class="enscript-keyword">return</span> <span class="enscript-type">type</span>
	typedesc = method-&gt;method_types;
	typedesc = SkipFirstType (typedesc);
	
	// Next, skip stack <span class="enscript-type">size</span>
	<span class="enscript-keyword">while</span> ((*typedesc &gt;= <span class="enscript-string">'0'</span>) &amp;&amp; (*typedesc &lt;= <span class="enscript-string">'9'</span>)) 
		typedesc += 1;
	
	// Now, we have the arguments - count how many
	nargs = 0;
	<span class="enscript-keyword">while</span> (*typedesc)
	{
		// Traverse argument <span class="enscript-type">type</span>
		typedesc = SkipFirstType (typedesc);
		
		// Traverse (possibly negative) argument offset
		<span class="enscript-keyword">if</span> (*typedesc == <span class="enscript-string">'-'</span>)
			typedesc += 1;
		<span class="enscript-keyword">while</span> ((*typedesc &gt;= <span class="enscript-string">'0'</span>) &amp;&amp; (*typedesc &lt;= <span class="enscript-string">'9'</span>)) 
			typedesc += 1;
		
		// Made it past an argument
		nargs += 1;
	}
	
	<span class="enscript-keyword">return</span> nargs;
}

/***********************************************************************
 * method_getSizeOfArguments.
 **********************************************************************/
#ifndef __alpha__
unsigned	method_getSizeOfArguments	(Method		method)
{
	const <span class="enscript-type">char</span> *		typedesc;
	unsigned		stack_size;
#<span class="enscript-keyword">if</span> defined(__ppc__) || defined(ppc)
	unsigned		trueBaseOffset;
	unsigned		foundBaseOffset;
#endif
	
	// Get our starting points
	stack_size = 0;
	typedesc = method-&gt;method_types;

	// Skip the <span class="enscript-keyword">return</span> <span class="enscript-type">type</span>
#<span class="enscript-keyword">if</span> defined (__ppc__) || defined(ppc)
	// Struct returns cause the parameters to be bumped
	// by a register, so the offset to the receiver is
	// 4 instead of the normal 0.
	trueBaseOffset = (*typedesc == <span class="enscript-string">'{'</span>) ? 4 : 0;
#endif
	typedesc = SkipFirstType (typedesc);	
	
	// Convert ASCII number string to integer
	<span class="enscript-keyword">while</span> ((*typedesc &gt;= <span class="enscript-string">'0'</span>) &amp;&amp; (*typedesc &lt;= <span class="enscript-string">'9'</span>)) 
		stack_size = (stack_size * 10) + (*typedesc++ - <span class="enscript-string">'0'</span>);
#<span class="enscript-keyword">if</span> defined (__ppc__) || defined(ppc)
	// NOTE: This is a temporary measure pending a compiler <span class="enscript-type">fix</span>.
	// Work around PowerPC compiler bug wherein the method argument
	// string contains an incorrect value <span class="enscript-keyword">for</span> the &quot;stack <span class="enscript-type">size</span>.&quot;
	// Generally, the <span class="enscript-type">size</span> is reported 4 bytes too small, so we apply
	// that fudge <span class="enscript-type">factor</span>.  Unfortunately, there is at least one <span class="enscript-type">case</span>
	// where the <span class="enscript-keyword">error</span> is something other than -4: when the last
	// parameter is a <span class="enscript-type">double</span>, the reported stack is much too high
	// (about 32 bytes).  We do <span class="enscript-type">not</span> attempt to detect that <span class="enscript-type">case</span>.
	// The result of returning a too-high value is that objc_msgSendv
	// can bus <span class="enscript-keyword">error</span> <span class="enscript-keyword">if</span> the destination of the marg_list copying
	// butts up against excluded memory.
	// This <span class="enscript-type">fix</span> disables itself when it sees a correctly built
	// <span class="enscript-type">type</span> string (<span class="enscript-type">i</span>.e. the offset <span class="enscript-keyword">for</span> the Id is correct).  This
	// keeps us out of lockstep with the compiler.

	// skip the <span class="enscript-string">'@'</span> marking the Id field
	typedesc = SkipFirstType (typedesc);

	// pick up the offset <span class="enscript-keyword">for</span> the Id field
	foundBaseOffset = 0;
	<span class="enscript-keyword">while</span> ((*typedesc &gt;= <span class="enscript-string">'0'</span>) &amp;&amp; (*typedesc &lt;= <span class="enscript-string">'9'</span>)) 
		foundBaseOffset = (foundBaseOffset * 10) + (*typedesc++ - <span class="enscript-string">'0'</span>);

	// add fudge <span class="enscript-type">factor</span> iff the Id field offset was wrong
	<span class="enscript-keyword">if</span> (foundBaseOffset != trueBaseOffset)
		stack_size += 4;
#endif

	<span class="enscript-keyword">return</span> stack_size;
}

#<span class="enscript-keyword">else</span> // __alpha__
// XXX Getting the <span class="enscript-type">size</span> of a <span class="enscript-type">type</span> is done <span class="enscript-type">all</span> over the place
// (Here, Foundation, remote project)! - Should unify

unsigned int	getSizeOfType	(const <span class="enscript-type">char</span> * <span class="enscript-type">type</span>, unsigned int * alignPtr);

unsigned	method_getSizeOfArguments	   (Method	method)
{
	const <span class="enscript-type">char</span> *	<span class="enscript-type">type</span>;
	int		<span class="enscript-type">size</span>;
	int		index;
	int		align;
	int		offset;
	unsigned	stack_size;
	int		nargs;
	
	nargs		= method_getNumberOfArguments (method);
	stack_size	= (*method-&gt;method_types == <span class="enscript-string">'{'</span>) ? sizeof(void *) : 0;
	
	<span class="enscript-keyword">for</span> (index = 0; index &lt; nargs; index += 1)
	{
		(void) method_getArgumentInfo (method, index, &amp;<span class="enscript-type">type</span>, &amp;offset);
		<span class="enscript-type">size</span> = getSizeOfType (<span class="enscript-type">type</span>, &amp;align);
		stack_size += ((<span class="enscript-type">size</span> + 7) &amp; ~7);
	}
	
	<span class="enscript-keyword">return</span> stack_size;
}
#endif // __alpha__

/***********************************************************************
 * method_getArgumentInfo.
 **********************************************************************/
unsigned	method_getArgumentInfo	       (Method		method,
						int		arg, 
						const <span class="enscript-type">char</span> **	<span class="enscript-type">type</span>,
						int *		offset)
{
	const <span class="enscript-type">char</span> *	typedesc	   = method-&gt;method_types;
	unsigned	nargs		   = 0;
	unsigned	self_offset	   = 0;
	BOOL		offset_is_negative = NO;
	
	// First, skip the <span class="enscript-keyword">return</span> <span class="enscript-type">type</span>
	typedesc = SkipFirstType (typedesc);
	
	// Next, skip stack <span class="enscript-type">size</span>
	<span class="enscript-keyword">while</span> ((*typedesc &gt;= <span class="enscript-string">'0'</span>) &amp;&amp; (*typedesc &lt;= <span class="enscript-string">'9'</span>)) 
		typedesc += 1;
	
	// Now, we have the arguments - position typedesc to the appropriate argument
	<span class="enscript-keyword">while</span> (*typedesc &amp;&amp; nargs != arg)
	{
	
		// Skip argument <span class="enscript-type">type</span>
		typedesc = SkipFirstType (typedesc);
		
		<span class="enscript-keyword">if</span> (nargs == 0)
		{
			// Skip negative <span class="enscript-type">sign</span> in offset
			<span class="enscript-keyword">if</span> (*typedesc == <span class="enscript-string">'-'</span>)
			{
				offset_is_negative = YES;
				typedesc += 1;
			}
			<span class="enscript-keyword">else</span>
				offset_is_negative = NO;
	
			<span class="enscript-keyword">while</span> ((*typedesc &gt;= <span class="enscript-string">'0'</span>) &amp;&amp; (*typedesc &lt;= <span class="enscript-string">'9'</span>)) 
				self_offset = self_offset * 10 + (*typedesc++ - <span class="enscript-string">'0'</span>);
			<span class="enscript-keyword">if</span> (offset_is_negative) 
				self_offset = -(self_offset);
		
		}
		
		<span class="enscript-keyword">else</span>
		{
			// Skip (possibly negative) argument offset
			<span class="enscript-keyword">if</span> (*typedesc == <span class="enscript-string">'-'</span>) 
				typedesc += 1;
			<span class="enscript-keyword">while</span> ((*typedesc &gt;= <span class="enscript-string">'0'</span>) &amp;&amp; (*typedesc &lt;= <span class="enscript-string">'9'</span>)) 
				typedesc += 1;
		}
		
		nargs += 1;
	}
	
	<span class="enscript-keyword">if</span> (*typedesc)
	{
		unsigned arg_offset = 0;
		
		*<span class="enscript-type">type</span>	 = typedesc;
		typedesc = SkipFirstType (typedesc);
		
		<span class="enscript-keyword">if</span> (arg == 0)
		{
#ifdef hppa
			*offset = -sizeof(id);
#<span class="enscript-keyword">else</span>
			*offset = 0;
#endif // hppa			
		}
		
		<span class="enscript-keyword">else</span>
		{
			// Pick up (possibly negative) argument offset
			<span class="enscript-keyword">if</span> (*typedesc == <span class="enscript-string">'-'</span>)
			{
				offset_is_negative = YES;
				typedesc += 1;
			}
			<span class="enscript-keyword">else</span>
				offset_is_negative = NO;

			<span class="enscript-keyword">while</span> ((*typedesc &gt;= <span class="enscript-string">'0'</span>) &amp;&amp; (*typedesc &lt;= <span class="enscript-string">'9'</span>)) 
				arg_offset = arg_offset * 10 + (*typedesc++ - <span class="enscript-string">'0'</span>);
			<span class="enscript-keyword">if</span> (offset_is_negative) 
				arg_offset = - arg_offset;
		
#ifdef hppa
			// For stacks <span class="enscript-type">which</span> grow up, since margs points
			// to the top of the stack <span class="enscript-type">or</span> the END of the args, 
			// the first offset is at -sizeof(id) rather than 0.
			self_offset += sizeof(id);
#endif
			*offset = arg_offset - self_offset;
		}
	
	}
	
	<span class="enscript-keyword">else</span>
	{
		*<span class="enscript-type">type</span>	= 0;
		*offset	= 0;
	}
	
	<span class="enscript-keyword">return</span> nargs;
}

/***********************************************************************
 * _objc_create_zone.
 **********************************************************************/

void *		_objc_create_zone		   (void)
{
	static void *_objc_z = (void *)0xffffffff;
	<span class="enscript-keyword">if</span> ( _objc_z == (void *)0xffffffff ) {
            <span class="enscript-type">char</span> *s = getenv(&quot;OBJC_USE_OBJC_ZONE&quot;);
            <span class="enscript-keyword">if</span> ( s ) {
                <span class="enscript-keyword">if</span> ( (*s == <span class="enscript-string">'1'</span>) || (*s == <span class="enscript-string">'y'</span>) || (*s == <span class="enscript-string">'Y'</span>) ) {
                    _objc_z = malloc_create_zone(vm_page_size, 0);
                    malloc_set_zone_name(_objc_z, &quot;ObjC&quot;);
                }
            }
            <span class="enscript-keyword">if</span> ( _objc_z == (void *)0xffffffff ) {
                _objc_z = malloc_default_zone();
            }
	}
	<span class="enscript-keyword">return</span> _objc_z;
}

/***********************************************************************
 * cache collection.
 **********************************************************************/
#ifdef OBJC_COLLECTING_CACHE

static unsigned long	_get_pc_for_thread     (mach_port_t	thread)
#ifdef hppa
{
		struct hp_pa_frame_thread_state		state;
		unsigned int count = HPPA_FRAME_THREAD_STATE_COUNT;
		thread_get_state (thread, HPPA_FRAME_THREAD_STATE, (thread_state_t)&amp;state, &amp;count);
		<span class="enscript-keyword">return</span> state.ts_pcoq_front;
}
#elif defined(sparc)
{
		struct sparc_thread_state_regs		state;
		unsigned int count = SPARC_THREAD_STATE_REGS_COUNT;
		thread_get_state (thread, SPARC_THREAD_STATE_REGS, (thread_state_t)&amp;state, &amp;count);
		<span class="enscript-keyword">return</span> state.regs.r_pc;
}
#elif defined(__i386__) || defined(i386)
{
		i386_thread_state_t			state;
		unsigned int count = i386_THREAD_STATE_COUNT;
		thread_get_state (thread, i386_THREAD_STATE, (thread_state_t)&amp;state, &amp;count);
		<span class="enscript-keyword">return</span> state.eip;
}
#elif defined(m68k)
{
		struct m68k_thread_state_regs		state;
		unsigned int count = M68K_THREAD_STATE_REGS_COUNT;
		thread_get_state (thread, M68K_THREAD_STATE_REGS, (thread_state_t)&amp;state, &amp;count);
		<span class="enscript-keyword">return</span> state.pc;
}
#elif defined(__ppc__) || defined(ppc)
{
		struct ppc_thread_state			state;
		unsigned int count = PPC_THREAD_STATE_COUNT;
		thread_get_state (thread, PPC_THREAD_STATE, (thread_state_t)&amp;state, &amp;count);
		<span class="enscript-keyword">return</span> state.srr0;
}	
#<span class="enscript-keyword">else</span>
{
	#<span class="enscript-keyword">error</span> _get_pc_for_thread () <span class="enscript-type">not</span> implemented <span class="enscript-keyword">for</span> this architecture
}
#endif

/***********************************************************************
 * _collecting_in_critical.
 **********************************************************************/
OBJC_EXPORT unsigned long	objc_entryPoints<span class="enscript-type">[</span><span class="enscript-type">]</span>;
OBJC_EXPORT unsigned long	objc_exitPoints<span class="enscript-type">[</span><span class="enscript-type">]</span>;

static int	_collecting_in_critical		(void)
{
	thread_act_port_array_t		threads;
	unsigned			number;
	unsigned			count;
	kern_return_t		ret;
	int					result;
	mach_port_t mythread = pthread_mach_thread_np(pthread_self());
	
	// Get a list of <span class="enscript-type">all</span> the threads in the current task
	ret = task_threads (mach_task_self (), &amp;threads, &amp;number);
	<span class="enscript-keyword">if</span> (ret != KERN_SUCCESS)
	{
		_objc_inform (&quot;objc: task_thread failed\n&quot;);
		exit (1);
	}
	
	// Check whether <span class="enscript-type">any</span> thread is in the cache lookup code
	result = 0;
	<span class="enscript-keyword">for</span> (count = 0; !result &amp;&amp; (count &lt; number); count += 1)
	{
		int				region;
		unsigned long	pc;
	
		// Don<span class="enscript-keyword">'</span>t bother checking ourselves
		<span class="enscript-keyword">if</span> (threads<span class="enscript-type">[</span>count<span class="enscript-type">]</span> == mythread)
			continue;
		
		// Find out where thread is executing
		pc = _get_pc_for_thread (threads<span class="enscript-type">[</span>count<span class="enscript-type">]</span>);
	
		// Check whether it is in the cache lookup code
		<span class="enscript-keyword">for</span> (region = 0; !result &amp;&amp; (objc_entryPoints<span class="enscript-type">[</span>region<span class="enscript-type">]</span> != 0); region += 1)
		{
			<span class="enscript-keyword">if</span> ((pc &gt;= objc_entryPoints<span class="enscript-type">[</span>region<span class="enscript-type">]</span>) &amp;&amp;
				(pc &lt;= objc_exitPoints<span class="enscript-type">[</span>region<span class="enscript-type">]</span>))
				result = 1;
		}
	}
	// Deallocate the port rights <span class="enscript-keyword">for</span> the threads
	<span class="enscript-keyword">for</span> (count = 0; count &lt; number; count++) {
		mach_port_deallocate(mach_task_self (), threads<span class="enscript-type">[</span>count<span class="enscript-type">]</span>);
	}
	
	// Deallocate the thread list
	vm_deallocate (mach_task_self (), (vm_address_t) threads, sizeof(threads) * number);
	
	// Return our finding
	<span class="enscript-keyword">return</span> result;
}

/***********************************************************************
 * _garbage_make_room.  Ensure that there is enough room <span class="enscript-keyword">for</span> at least
 * one <span class="enscript-type">more</span> ref in the garbage.
 **********************************************************************/

// amount of memory represented by <span class="enscript-type">all</span> refs in the garbage
static int garbage_byte_size	= 0;

// do <span class="enscript-type">not</span> empty the garbage until garbage_byte_size gets at least this big
static int garbage_threshold	= 1024;

// table of refs to free
static void **garbage_refs	= 0;

// current number of refs in garbage_refs
static int garbage_count	= 0;

// capacity of current garbage_refs
static int garbage_max		= 0;

// capacity of initial garbage_refs
enum {
	INIT_GARBAGE_COUNT	= 128
};

static void	_garbage_make_room		(void)
{
	static int	first = 1;
	volatile void *	tempGarbage;

	// Create the collection table the first time it is needed
	<span class="enscript-keyword">if</span> (first)
	{
		first		= 0;
		garbage_refs	= malloc_zone_malloc (_objc_create_zone(),
						INIT_GARBAGE_COUNT * sizeof(void *));
		garbage_max	= INIT_GARBAGE_COUNT;
	}
	
	// Double the table <span class="enscript-keyword">if</span> it is <span class="enscript-type">full</span>
	<span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> (garbage_count == garbage_max)
	{
		tempGarbage	= malloc_zone_realloc ((void *) _objc_create_zone(),
						(void *) garbage_refs,
						(size_t) garbage_max * 2 * sizeof(void *));
		garbage_refs	= (void **) tempGarbage;
		garbage_max	*= 2;
	}
}

/***********************************************************************
 * _cache_collect_free.  Add the specified malloc<span class="enscript-keyword">'</span>d memory to the list
 * of them to free at some later point.
 **********************************************************************/
static void	_cache_collect_free    (void *		data,
									BOOL		tryCollect)
{
	static <span class="enscript-type">char</span> *report_garbage = (<span class="enscript-type">char</span> *)0xffffffff;

	<span class="enscript-keyword">if</span> ((<span class="enscript-type">char</span> *)0xffffffff == report_garbage) {	
		// Check whether to <span class="enscript-type">log</span> our activity
		report_garbage = getenv (&quot;OBJC_REPORT_GARBAGE&quot;);
	}

	// Synchronize
	OBJC_LOCK(&amp;cacheCollectionLock);
	
	// Insert new element in garbage list
	// Note that we do this even <span class="enscript-keyword">if</span> we <span class="enscript-keyword">end</span> up free<span class="enscript-keyword">'</span>ing everything
	_garbage_make_room ();	
	garbage_byte_size += malloc_size (data);
	garbage_refs<span class="enscript-type">[</span>garbage_count++<span class="enscript-type">]</span> = data;
	
	// Log our progress
	<span class="enscript-keyword">if</span> (tryCollect &amp;&amp; report_garbage)
		_objc_inform (&quot;total of <span class="enscript-comment">%d bytes of garbage ...&quot;, garbage_byte_size);
</span>	
	// Done <span class="enscript-keyword">if</span> caller says <span class="enscript-type">not</span> to empty <span class="enscript-type">or</span> the garbage is <span class="enscript-type">not</span> <span class="enscript-type">full</span>
	<span class="enscript-keyword">if</span> (!tryCollect || (garbage_byte_size &lt; garbage_threshold))
	{
		OBJC_UNLOCK(&amp;cacheCollectionLock);
		<span class="enscript-keyword">if</span> (tryCollect &amp;&amp; report_garbage)
			_objc_inform (&quot;below threshold\n&quot;);
		
		<span class="enscript-keyword">return</span>;
	}
	
	// Synchronize garbage collection with messageLock holders
	<span class="enscript-keyword">if</span> (OBJC_TRYLOCK(&amp;messageLock))
	{
		// Synchronize garbage collection with cache lookers
		<span class="enscript-keyword">if</span> (!_collecting_in_critical ())
		{
			// Log our progress
			<span class="enscript-keyword">if</span> (tryCollect &amp;&amp; report_garbage)
				_objc_inform (&quot;collecting!\n&quot;);
			
			// Dispose <span class="enscript-type">all</span> refs <span class="enscript-type">now</span> in the garbage
			<span class="enscript-keyword">while</span> (garbage_count)
				free (garbage_refs<span class="enscript-type">[</span>--garbage_count<span class="enscript-type">]</span>);
			
			// Clear the total <span class="enscript-type">size</span> indicator
			garbage_byte_size = 0;
		}
		
		// Someone is actively looking in the cache
		<span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> (tryCollect &amp;&amp; report_garbage)
			_objc_inform (&quot;in critical region\n&quot;);
		
		OBJC_UNLOCK(&amp;messageLock);
	}
	
	// Someone already holds messageLock
	<span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> (tryCollect &amp;&amp; report_garbage)
		_objc_inform (&quot;messageLock taken\n&quot;);
	
	OBJC_UNLOCK(&amp;cacheCollectionLock);
}
#endif // OBJC_COLLECTING_CACHE


/***********************************************************************
 * _cache_print.
 **********************************************************************/
static void	_cache_print	       (Cache		cache)
{
	unsigned int	index;
	unsigned int	count;
	
	count = cache-&gt;mask + 1;
	<span class="enscript-keyword">for</span> (index = 0; index &lt; count; index += 1)
		<span class="enscript-keyword">if</span> (CACHE_BUCKET_VALID(cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>))
		{
			<span class="enscript-keyword">if</span> (CACHE_BUCKET_IMP(cache-&gt;buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>) == &amp;_objc_msgForward)
				printf (&quot;does <span class="enscript-type">not</span> recognize: \n&quot;);
			printf (&quot;<span class="enscript-comment">%s\n&quot;, (const char *) CACHE_BUCKET_NAME(cache-&gt;buckets[index]));
</span>		}
}

/***********************************************************************
 * _class_printMethodCaches.
 **********************************************************************/
void	_class_printMethodCaches       (Class		cls)
{
	<span class="enscript-keyword">if</span> (((struct objc_class *)cls)-&gt;cache == &amp;emptyCache)
		printf (&quot;no instance-method cache <span class="enscript-keyword">for</span> <span class="enscript-type">class</span> <span class="enscript-comment">%s\n&quot;, ((struct objc_class *)cls)-&gt;name);
</span>	
	<span class="enscript-keyword">else</span>
	{
		printf (&quot;instance-method cache <span class="enscript-keyword">for</span> <span class="enscript-type">class</span> <span class="enscript-comment">%s:\n&quot;, ((struct objc_class *)cls)-&gt;name);
</span>		_cache_print (((struct objc_class *)cls)-&gt;cache);
	}
	
	<span class="enscript-keyword">if</span> (((struct objc_class * )((struct objc_class * )cls)-&gt;<span class="enscript-type">isa</span>)-&gt;cache == &amp;emptyCache)
		printf (&quot;no <span class="enscript-type">class</span>-method cache <span class="enscript-keyword">for</span> <span class="enscript-type">class</span> <span class="enscript-comment">%s\n&quot;, ((struct objc_class *)cls)-&gt;name);
</span>	
	<span class="enscript-keyword">else</span>
	{
		printf (&quot;<span class="enscript-type">class</span>-method cache <span class="enscript-keyword">for</span> <span class="enscript-type">class</span> <span class="enscript-comment">%s:\n&quot;, ((struct objc_class *)cls)-&gt;name);
</span>		_cache_print (((struct objc_class * )((struct objc_class * )cls)-&gt;<span class="enscript-type">isa</span>)-&gt;cache);
	}
}

/***********************************************************************
 * <span class="enscript-type">log2</span>.
 **********************************************************************/
static unsigned int	<span class="enscript-type">log2</span>	       (unsigned int	x)
{
	unsigned int	<span class="enscript-type">log</span>;

	<span class="enscript-type">log</span> = 0;
	<span class="enscript-keyword">while</span> (x &gt;&gt;= 1)
		<span class="enscript-type">log</span> += 1;

	<span class="enscript-keyword">return</span> <span class="enscript-type">log</span>;
}

/***********************************************************************
 * _class_printDuplicateCacheEntries.
 **********************************************************************/
void	_class_printDuplicateCacheEntries	   (BOOL	detail) 
{
	NXHashTable *	class_hash;
	NXHashState	state;
	struct objc_class *		cls;
	unsigned int	duplicates;
	unsigned int	index1;
	unsigned int	index2;
	unsigned int	mask;
	unsigned int	count;
	unsigned int	isMeta;
	Cache		cache;
		

	printf (&quot;Checking <span class="enscript-keyword">for</span> duplicate cache entries \n&quot;);

	// Outermost loop - iterate over <span class="enscript-type">all</span> classes
	class_hash = objc_getClasses ();
	state	   = NXInitHashState (class_hash);
	duplicates = 0;
	<span class="enscript-keyword">while</span> (NXNextHashState (class_hash, &amp;state, (void **) &amp;cls))
	{	
		// Control loop - do given class<span class="enscript-keyword">'</span> cache, then its isa<span class="enscript-keyword">'</span>s cache
		<span class="enscript-keyword">for</span> (isMeta = 0; isMeta &lt;= 1; isMeta += 1)
		{
			// Select cache of interest <span class="enscript-type">and</span> make sure it exists
			cache = isMeta ? cls-&gt;<span class="enscript-type">isa</span>-&gt;cache : ((struct objc_class *)cls)-&gt;cache;
			<span class="enscript-keyword">if</span> (cache == &amp;emptyCache)
				continue;
			
			// Middle loop - check each entry in the given cache
			mask  = cache-&gt;mask;
			count = mask + 1;
			<span class="enscript-keyword">for</span> (index1 = 0; index1 &lt; count; index1 += 1)
			{
				// Skip invalid entry
				<span class="enscript-keyword">if</span> (!CACHE_BUCKET_VALID(cache-&gt;buckets<span class="enscript-type">[</span>index1<span class="enscript-type">]</span>))
					continue;
				
				// Inner loop - check that given entry matches no later entry
				<span class="enscript-keyword">for</span> (index2 = index1 + 1; index2 &lt; count; index2 += 1)
				{
					// Skip invalid entry
					<span class="enscript-keyword">if</span> (!CACHE_BUCKET_VALID(cache-&gt;buckets<span class="enscript-type">[</span>index2<span class="enscript-type">]</span>))
						continue;

					// Check <span class="enscript-keyword">for</span> duplication by method name comparison
					<span class="enscript-keyword">if</span> (<span class="enscript-type">strcmp</span> ((<span class="enscript-type">char</span> *) CACHE_BUCKET_NAME(cache-&gt;buckets<span class="enscript-type">[</span>index1<span class="enscript-type">]</span>),
						    (<span class="enscript-type">char</span> *) CACHE_BUCKET_NAME(cache-&gt;buckets<span class="enscript-type">[</span>index2<span class="enscript-type">]</span>)) == 0)
					{
						<span class="enscript-keyword">if</span> (detail)
							printf (&quot;<span class="enscript-comment">%s %s\n&quot;, ((struct objc_class *)cls)-&gt;name, (char *) CACHE_BUCKET_NAME(cache-&gt;buckets[index1]));
</span>						duplicates += 1;
						<span class="enscript-keyword">break</span>;
					}
				}
			}
		}
	}
	
	// Log the findings
	printf (&quot;duplicates = <span class="enscript-comment">%d\n&quot;, duplicates);
</span>	printf (&quot;total cache fills = <span class="enscript-comment">%d\n&quot;, totalCacheFills);
</span>}

/***********************************************************************
 * PrintCacheHeader.
 **********************************************************************/
static void	PrintCacheHeader        (void)
{
#ifdef OBJC_INSTRUMENTED
	printf (&quot;Cache  Cache  Slots  Avg    Max   AvgS  MaxS  AvgS  MaxS  TotalD   AvgD  MaxD  TotalD   AvgD  MaxD  TotD  AvgD  MaxD\n&quot;);
	printf (&quot;Size   Count  Used   Used   Used  Hit   Hit   Miss  Miss  Hits     Prbs  Prbs  Misses   Prbs  Prbs  Flsh  Flsh  Flsh\n&quot;);
	printf (&quot;-----  -----  -----  -----  ----  ----  ----  ----  ----  -------  ----  ----  -------  ----  ----  ----  ----  ----\n&quot;);
#<span class="enscript-keyword">else</span>
	printf (&quot;Cache  Cache  Slots  Avg    Max   AvgS  MaxS  AvgS  MaxS\n&quot;);
	printf (&quot;Size   Count  Used   Used   Used  Hit   Hit   Miss  Miss\n&quot;);
	printf (&quot;-----  -----  -----  -----  ----  ----  ----  ----  ----\n&quot;);
#endif
}

/***********************************************************************
 * PrintCacheInfo.
 **********************************************************************/
static	void		PrintCacheInfo (unsigned int	cacheSize,
					unsigned int	cacheCount,
					unsigned int	slotsUsed,
					float		avgUsed,
					unsigned int	maxUsed,
					float		avgSHit,
					unsigned int	maxSHit,
					float		avgSMiss,
					unsigned int	maxSMiss
#ifdef OBJC_INSTRUMENTED
					, unsigned int	totDHits,
					float		avgDHit,
					unsigned int	maxDHit,
					unsigned int	totDMisses,
					float		avgDMiss,
					unsigned int	maxDMiss,
					unsigned int	totDFlsh,
					float		avgDFlsh,
					unsigned int	maxDFlsh
#endif
						)
{
#ifdef OBJC_INSTRUMENTED
	printf (&quot;<span class="enscript-comment">%5u  %5u  %5u  %5.1f  %4u  %4.1f  %4u  %4.1f  %4u  %7u  %4.1f  %4u  %7u  %4.1f  %4u  %4u  %4.1f  %4u\n&quot;,
</span>#<span class="enscript-keyword">else</span>
	printf (&quot;<span class="enscript-comment">%5u  %5u  %5u  %5.1f  %4u  %4.1f  %4u  %4.1f  %4u\n&quot;,
</span>#endif
			cacheSize, cacheCount, slotsUsed, avgUsed, maxUsed, avgSHit, maxSHit, avgSMiss, maxSMiss
#ifdef OBJC_INSTRUMENTED
			, totDHits, avgDHit, maxDHit, totDMisses, avgDMiss, maxDMiss, totDFlsh, avgDFlsh, maxDFlsh
#endif
	);

}

#ifdef OBJC_INSTRUMENTED
/***********************************************************************
 * PrintCacheHistogram.  Show the non-zero entries from the specified
 * cache histogram.
 **********************************************************************/
static void	PrintCacheHistogram    (<span class="enscript-type">char</span> *		<span class="enscript-type">title</span>,
					unsigned int *	firstEntry,
					unsigned int	entryCount)
{
	unsigned int	index;
	unsigned int *	thisEntry;

	printf (&quot;<span class="enscript-comment">%s\n&quot;, title);
</span>	printf (&quot;    Probes    Tally\n&quot;);
	printf (&quot;    ------    -----\n&quot;);
	<span class="enscript-keyword">for</span> (index = 0, thisEntry = firstEntry;
	     index &lt; entryCount;
	     index += 1, thisEntry += 1)
	{
		<span class="enscript-keyword">if</span> (*thisEntry == 0)
			continue;

		printf (&quot;    <span class="enscript-comment">%6d    %5d\n&quot;, index, *thisEntry);
</span>	}
}
#endif

/***********************************************************************
 * _class_printMethodCacheStatistics.
 **********************************************************************/

#define MAX_LOG2_SIZE		32
#define MAX_CHAIN_SIZE		100

void		_class_printMethodCacheStatistics		(void)
{
	unsigned int	isMeta;
	unsigned int	index;
	NXHashTable *	class_hash;
	NXHashState	state;
	struct objc_class *		cls;
	unsigned int	totalChain;
	unsigned int	totalMissChain;
	unsigned int	maxChain;
	unsigned int	maxMissChain;
	unsigned int	classCount;
	unsigned int	negativeEntryCount;
	unsigned int	cacheExpandCount;
	unsigned int	cacheCountBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	totalEntriesBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	maxEntriesBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	totalChainBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	totalMissChainBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	totalMaxChainBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	totalMaxMissChainBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span> = {{0}};
	unsigned int	maxChainBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	maxMissChainBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	chainCount<span class="enscript-type">[</span>MAX_CHAIN_SIZE<span class="enscript-type">]</span>		  = {0};
	unsigned int	missChainCount<span class="enscript-type">[</span>MAX_CHAIN_SIZE<span class="enscript-type">]</span>		  = {0};
#ifdef OBJC_INSTRUMENTED
	unsigned int	hitCountBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	hitProbesBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	maxHitProbesBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	missCountBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	missProbesBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	maxMissProbesBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	flushCountBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	flushedEntriesBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span>	  = {{0}};
	unsigned int	maxFlushedEntriesBySize<span class="enscript-type">[</span>2<span class="enscript-type">]</span><span class="enscript-type">[</span>MAX_LOG2_SIZE<span class="enscript-type">]</span> = {{0}};
#endif

	printf (&quot;Printing cache statistics\n&quot;);
	
	// Outermost loop - iterate over <span class="enscript-type">all</span> classes
	class_hash		= objc_getClasses ();
	state			= NXInitHashState (class_hash);
	classCount		= 0;
	negativeEntryCount	= 0;
	cacheExpandCount	= 0;
	<span class="enscript-keyword">while</span> (NXNextHashState (class_hash, &amp;state, (void **) &amp;cls))
	{
		// Tally classes
		classCount += 1;

		// Control loop - do given class<span class="enscript-keyword">'</span> cache, then its isa<span class="enscript-keyword">'</span>s cache
		<span class="enscript-keyword">for</span> (isMeta = 0; isMeta &lt;= 1; isMeta += 1)
		{
			Cache		cache;
			unsigned int	mask;
			unsigned int	log2Size;
			unsigned int	entryCount;

			// Select cache of interest
			cache = isMeta ? cls-&gt;<span class="enscript-type">isa</span>-&gt;cache : ((struct objc_class *)cls)-&gt;cache;
			
			// Ignore empty cache<span class="enscript-keyword">...</span> should we?
			<span class="enscript-keyword">if</span> (cache == &amp;emptyCache)
				continue;

			// Middle loop - do each entry in the given cache
			mask		= cache-&gt;mask;
			entryCount	= 0;
			totalChain	= 0;
			totalMissChain	= 0;
			maxChain	= 0;
			maxMissChain	= 0;
			<span class="enscript-keyword">for</span> (index = 0; index &lt; mask + 1; index += 1)
			{
				Method *			buckets;
				Method				method;
				uarith_t			hash;
				uarith_t			methodChain;
				uarith_t			methodMissChain;
				uarith_t			index2;
								
				// If entry is invalid, the only item of
				// interest is that future insert hashes 
				// to this entry can use it directly.
				buckets = cache-&gt;buckets;
				<span class="enscript-keyword">if</span> (!CACHE_BUCKET_VALID(buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>))
				{
					missChainCount<span class="enscript-type">[</span>0<span class="enscript-type">]</span> += 1;
					continue;
				}

				method	= buckets<span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
				
				// Tally valid entries
				entryCount += 1;
				
				// Tally &quot;forward::&quot; entries
				<span class="enscript-keyword">if</span> (CACHE_BUCKET_IMP(method) == &amp;_objc_msgForward)
					negativeEntryCount += 1;
				
				// Calculate search distance (chain <span class="enscript-type">length</span>) <span class="enscript-keyword">for</span> this method
				hash	    = (uarith_t) CACHE_BUCKET_NAME(method);
				methodChain = ((index - hash) &amp; mask);
				
				// Tally chains of this <span class="enscript-type">length</span>
				<span class="enscript-keyword">if</span> (methodChain &lt; MAX_CHAIN_SIZE)
					chainCount<span class="enscript-type">[</span>methodChain<span class="enscript-type">]</span> += 1;
				
				// Keep <span class="enscript-type">sum</span> of <span class="enscript-type">all</span> chain lengths
				totalChain += methodChain;
				
				// Record greatest chain <span class="enscript-type">length</span>
				<span class="enscript-keyword">if</span> (methodChain &gt; maxChain)
					maxChain = methodChain;
				
				// Calculate search distance <span class="enscript-keyword">for</span> miss that hashes here
				index2	= index;
				<span class="enscript-keyword">while</span> (CACHE_BUCKET_VALID(buckets<span class="enscript-type">[</span>index2<span class="enscript-type">]</span>))
				{
					index2 += 1;
					index2 &amp;= mask;
				}
				methodMissChain = ((index2 - index) &amp; mask);
				
				// Tally miss chains of this <span class="enscript-type">length</span>
				<span class="enscript-keyword">if</span> (methodMissChain &lt; MAX_CHAIN_SIZE)
					missChainCount<span class="enscript-type">[</span>methodMissChain<span class="enscript-type">]</span> += 1;

				// Keep <span class="enscript-type">sum</span> of <span class="enscript-type">all</span> miss chain lengths in this <span class="enscript-type">class</span>
				totalMissChain += methodMissChain;

				// Record greatest miss chain <span class="enscript-type">length</span>
				<span class="enscript-keyword">if</span> (methodMissChain &gt; maxMissChain)
					maxMissChain = methodMissChain;
			}

			// Factor this cache into statistics about caches of the same
			// <span class="enscript-type">type</span> <span class="enscript-type">and</span> <span class="enscript-type">size</span> (<span class="enscript-type">all</span> caches are a <span class="enscript-type">power</span> of two in <span class="enscript-type">size</span>)
			log2Size						 = <span class="enscript-type">log2</span> (mask + 1);
			cacheCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>			+= 1;
			totalEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>			+= entryCount;
			<span class="enscript-keyword">if</span> (entryCount &gt; maxEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>)
				maxEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>		 = entryCount;
			totalChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>			+= totalChain;
			totalMissChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>			+= totalMissChain;
			totalMaxChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>			+= maxChain;
			totalMaxMissChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>		+= maxMissChain;
			<span class="enscript-keyword">if</span> (maxChain &gt; maxChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>)
				maxChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>		 = maxChain;
			<span class="enscript-keyword">if</span> (maxMissChain &gt; maxMissChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>)
				maxMissChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>		 = maxMissChain;
#ifdef OBJC_INSTRUMENTED
			{
			CacheInstrumentation *	cacheData;

			cacheData = CACHE_INSTRUMENTATION(cache);
			hitCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>			+= cacheData-&gt;hitCount;
			hitProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>			+= cacheData-&gt;hitProbes;
			<span class="enscript-keyword">if</span> (cacheData-&gt;maxHitProbes &gt; maxHitProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>)
				maxHitProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>		 = cacheData-&gt;maxHitProbes;
			missCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>			+= cacheData-&gt;missCount;
			missProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>			+= cacheData-&gt;missProbes;
			<span class="enscript-keyword">if</span> (cacheData-&gt;maxMissProbes &gt; maxMissProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>)
				maxMissProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>		 = cacheData-&gt;maxMissProbes;
			flushCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>			+= cacheData-&gt;flushCount;
			flushedEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>			+= cacheData-&gt;flushedEntries;
			<span class="enscript-keyword">if</span> (cacheData-&gt;maxFlushedEntries &gt; maxFlushedEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>)
				maxFlushedEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>log2Size<span class="enscript-type">]</span>	 = cacheData-&gt;maxFlushedEntries;
			}
#endif
			// Caches start with a <span class="enscript-type">power</span> of two number of entries, <span class="enscript-type">and</span> grow by doubling, so
			// we can calculate the number of <span class="enscript-type">times</span> this cache has expanded
			<span class="enscript-keyword">if</span> (isMeta)
				cacheExpandCount += log2Size - INIT_META_CACHE_SIZE_LOG2;
			<span class="enscript-keyword">else</span>
				cacheExpandCount += log2Size - INIT_CACHE_SIZE_LOG2;

		}
	}

	{
	unsigned int	cacheCountByType<span class="enscript-type">[</span>2<span class="enscript-type">]</span> = {0};
	unsigned int	totalCacheCount	    = 0;
	unsigned int	totalEntries	    = 0;
	unsigned int	maxEntries	    = 0;
	unsigned int	totalSlots	    = 0;
#ifdef OBJC_INSTRUMENTED
	unsigned int	totalHitCount	    = 0;
	unsigned int	totalHitProbes	    = 0;
	unsigned int	maxHitProbes	    = 0;
	unsigned int	totalMissCount	    = 0;
	unsigned int	totalMissProbes	    = 0;
	unsigned int	maxMissProbes	    = 0;
	unsigned int	totalFlushCount	    = 0;
	unsigned int	totalFlushedEntries = 0;
	unsigned int	maxFlushedEntries   = 0;
#endif
	
	totalChain	= 0;
	maxChain	= 0;
	totalMissChain	= 0;
	maxMissChain	= 0;
	
	// Sum information over <span class="enscript-type">all</span> caches
	<span class="enscript-keyword">for</span> (isMeta = 0; isMeta &lt;= 1; isMeta += 1)
	{
		<span class="enscript-keyword">for</span> (index = 0; index &lt; MAX_LOG2_SIZE; index += 1)
		{
			cacheCountByType<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span> += cacheCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			totalEntries	   += totalEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			totalSlots	   += cacheCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> * (1 &lt;&lt; index);
			totalChain	   += totalChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			<span class="enscript-keyword">if</span> (maxEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> &gt; maxEntries)
				maxEntries  = maxEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			<span class="enscript-keyword">if</span> (maxChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> &gt; maxChain)
				maxChain    = maxChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			totalMissChain	   += totalMissChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			<span class="enscript-keyword">if</span> (maxMissChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> &gt; maxMissChain)
				maxMissChain = maxMissChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
#ifdef OBJC_INSTRUMENTED
			totalHitCount	   += hitCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			totalHitProbes	   += hitProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			<span class="enscript-keyword">if</span> (maxHitProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> &gt; maxHitProbes)
				maxHitProbes = maxHitProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			totalMissCount	   += missCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			totalMissProbes	   += missProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			<span class="enscript-keyword">if</span> (maxMissProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> &gt; maxMissProbes)
				maxMissProbes = maxMissProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			totalFlushCount	   += flushCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			totalFlushedEntries += flushedEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			<span class="enscript-keyword">if</span> (maxFlushedEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> &gt; maxFlushedEntries)
				maxFlushedEntries = maxFlushedEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
#endif
		}

		totalCacheCount += cacheCountByType<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span>;
	}

	// Log our findings
	printf (&quot;There are <span class="enscript-comment">%u classes\n&quot;, classCount);
</span>
	<span class="enscript-keyword">for</span> (isMeta = 0; isMeta &lt;= 1; isMeta += 1)
	{
		// Number of this <span class="enscript-type">type</span> of <span class="enscript-type">class</span>
		printf    (&quot;\nThere are <span class="enscript-comment">%u %s-method caches, broken down by size (slot count):\n&quot;,
</span>				cacheCountByType<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span>,
				isMeta ? &quot;<span class="enscript-type">class</span>&quot; : &quot;instance&quot;);

		// Print header
		PrintCacheHeader ();

		// Keep <span class="enscript-type">format</span> consistent even <span class="enscript-keyword">if</span> there are caches of this kind
		<span class="enscript-keyword">if</span> (cacheCountByType<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span> == 0)
		{
			printf (&quot;(none)\n&quot;);
			continue;
		}

		// Usage information by cache <span class="enscript-type">size</span>
		<span class="enscript-keyword">for</span> (index = 0; index &lt; MAX_LOG2_SIZE; index += 1)
		{
			unsigned int	cacheCount;
			unsigned int	cacheSlotCount;
			unsigned int	cacheEntryCount;
			
			// Get number of caches of this <span class="enscript-type">type</span> <span class="enscript-type">and</span> <span class="enscript-type">size</span>
			cacheCount = cacheCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			<span class="enscript-keyword">if</span> (cacheCount == 0)
				continue;
			
			// Get the cache slot count <span class="enscript-type">and</span> the total number of valid entries
			cacheSlotCount  = (1 &lt;&lt; index);
			cacheEntryCount = totalEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>;

			// Give the analysis
			PrintCacheInfo (cacheSlotCount,
					cacheCount,
					cacheEntryCount,
					(float) cacheEntryCount / (float) cacheCount,
					maxEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>,
					(float) totalChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> / (float) cacheEntryCount,
					maxChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>,
					(float) totalMissChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> / (float) (cacheCount * cacheSlotCount),
					maxMissChainBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>
#ifdef OBJC_INSTRUMENTED
					, hitCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>,
					hitCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> ? 
					    (float) hitProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> / (float) hitCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> : 0.0,
					maxHitProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>,
					missCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>,
					missCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> ? 
					    (float) missProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> / (float) missCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> : 0.0,
					maxMissProbesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>,
					flushCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>,
					flushCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> ? 
					    (float) flushedEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> / (float) flushCountBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span> : 0.0,
					maxFlushedEntriesBySize<span class="enscript-type">[</span>isMeta<span class="enscript-type">]</span><span class="enscript-type">[</span>index<span class="enscript-type">]</span>
#endif
				     );
		}
	}

	// Give overall numbers
	printf (&quot;\nCumulative:\n&quot;);
	PrintCacheHeader ();
	PrintCacheInfo (totalSlots,
			totalCacheCount,
			totalEntries,
			(float) totalEntries / (float) totalCacheCount,
			maxEntries,
			(float) totalChain / (float) totalEntries,
			maxChain,
			(float) totalMissChain / (float) totalSlots,
			 maxMissChain
#ifdef OBJC_INSTRUMENTED
			, totalHitCount,
			totalHitCount ? 
			    (float) totalHitProbes / (float) totalHitCount : 0.0,
			maxHitProbes,
			totalMissCount,
			totalMissCount ? 
			    (float) totalMissProbes / (float) totalMissCount : 0.0,
			maxMissProbes,
			totalFlushCount,
			totalFlushCount ? 
			    (float) totalFlushedEntries / (float) totalFlushCount : 0.0,
			maxFlushedEntries
#endif
				);

	printf (&quot;\nNumber of \&quot;forward::\&quot; entries: <span class="enscript-comment">%d\n&quot;, negativeEntryCount);
</span>	printf (&quot;Number of cache expansions: <span class="enscript-comment">%d\n&quot;, cacheExpandCount);
</span>#ifdef OBJC_INSTRUMENTED
	printf (&quot;flush_caches:   total calls  total visits  average visits  <span class="enscript-type">max</span> visits  total classes  visits/<span class="enscript-type">class</span>\n&quot;);
	printf (&quot;                -----------  ------------  --------------  ----------  -------------  -------------\n&quot;);
	printf (&quot;  linear        <span class="enscript-comment">%11u  %12u  %14.1f  %10u  %13u  %12.2f\n&quot;,
</span>			LinearFlushCachesCount,
			LinearFlushCachesVisitedCount,
			LinearFlushCachesCount ?
			    (float) LinearFlushCachesVisitedCount / (float) LinearFlushCachesCount : 0.0,
			MaxLinearFlushCachesVisitedCount,
			LinearFlushCachesVisitedCount,
			1.0);
	printf (&quot;  nonlinear     <span class="enscript-comment">%11u  %12u  %14.1f  %10u  %13u  %12.2f\n&quot;,
</span>			NonlinearFlushCachesCount,
			NonlinearFlushCachesVisitedCount,
			NonlinearFlushCachesCount ?
			    (float) NonlinearFlushCachesVisitedCount / (float) NonlinearFlushCachesCount : 0.0,
			MaxNonlinearFlushCachesVisitedCount,
			NonlinearFlushCachesClassCount,
			NonlinearFlushCachesClassCount ? 
			    (float) NonlinearFlushCachesVisitedCount / (float) NonlinearFlushCachesClassCount : 0.0);
	printf (&quot;  ideal         <span class="enscript-comment">%11u  %12u  %14.1f  %10u  %13u  %12.2f\n&quot;,
</span>			LinearFlushCachesCount + NonlinearFlushCachesCount,
			IdealFlushCachesCount,
			LinearFlushCachesCount + NonlinearFlushCachesCount ?
			    (float) IdealFlushCachesCount / (float) (LinearFlushCachesCount + NonlinearFlushCachesCount) : 0.0,
			MaxIdealFlushCachesCount,
			LinearFlushCachesVisitedCount + NonlinearFlushCachesClassCount,
			LinearFlushCachesVisitedCount + NonlinearFlushCachesClassCount ? 
			    (float) IdealFlushCachesCount / (float) (LinearFlushCachesVisitedCount + NonlinearFlushCachesClassCount) : 0.0);

	PrintCacheHistogram (&quot;\nCache hit histogram:&quot;,  &amp;CacheHitHistogram<span class="enscript-type">[</span>0<span class="enscript-type">]</span>,  CACHE_HISTOGRAM_SIZE);
	PrintCacheHistogram (&quot;\nCache miss histogram:&quot;, &amp;CacheMissHistogram<span class="enscript-type">[</span>0<span class="enscript-type">]</span>, CACHE_HISTOGRAM_SIZE);
#endif

#<span class="enscript-keyword">if</span> 0
	printf (&quot;\nLookup chains:&quot;);
	<span class="enscript-keyword">for</span> (index = 0; index &lt; MAX_CHAIN_SIZE; index += 1)
	{
		<span class="enscript-keyword">if</span> (chainCount<span class="enscript-type">[</span>index<span class="enscript-type">]</span> != 0)
			printf (&quot;  <span class="enscript-comment">%u:%u&quot;, index, chainCount[index]);
</span>	}

	printf (&quot;\nMiss chains:&quot;);
	<span class="enscript-keyword">for</span> (index = 0; index &lt; MAX_CHAIN_SIZE; index += 1)
	{
		<span class="enscript-keyword">if</span> (missChainCount<span class="enscript-type">[</span>index<span class="enscript-type">]</span> != 0)
			printf (&quot;  <span class="enscript-comment">%u:%u&quot;, index, missChainCount[index]);
</span>	}

	printf (&quot;\nTotal memory usage <span class="enscript-keyword">for</span> cache data structures: <span class="enscript-comment">%lu bytes\n&quot;,
</span>		     totalCacheCount * (sizeof(struct objc_cache) - sizeof(Method)) +
		     	totalSlots * sizeof(Method) +
		     	negativeEntryCount * sizeof(struct objc_method));
#endif
	}
}

/***********************************************************************
 * checkUniqueness.
 **********************************************************************/
void		checkUniqueness	       (SEL		s1,
					SEL		s2)
{
	<span class="enscript-keyword">if</span> (s1 == s2)
		<span class="enscript-keyword">return</span>;
	
	<span class="enscript-keyword">if</span> (s1 &amp;&amp; s2 &amp;&amp; (<span class="enscript-type">strcmp</span> ((const <span class="enscript-type">char</span> *) s1, (const <span class="enscript-type">char</span> *) s2) == 0))
		_NXLogError (&quot;<span class="enscript-comment">%p != %p but !strcmp (%s, %s)\n&quot;, s1, s2, (char *) s1, (char *) s2);
</span>}

</pre>
<hr />
</body></html>