<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc-runtime.m</title>
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
<h1 style="margin:8px;" id="f1">objc-runtime.m&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
 * objc-runtime.m
 * Copyright 1988-1996, NeXT Software, Inc.
 * Author:	s. naroff
 *
 **********************************************************************/

/***********************************************************************
 * Imports.
 **********************************************************************/

#<span class="enscript-keyword">if</span> defined(WIN32)
#include &lt;winnt-pdo.h&gt;
#endif

#<span class="enscript-keyword">if</span> defined(NeXT_PDO)
#import &lt;pdo.h&gt;		// <span class="enscript-keyword">for</span> pdo_malloc <span class="enscript-type">and</span> pdo_free defines
#elif defined(__MACH__)
#include &lt;mach-o/ldsyms.h&gt;
#include &lt;mach-o/dyld.h&gt;
#include &lt;mach/vm_statistics.h&gt;
#endif

#import &lt;objc/objc-runtime.h&gt;
#import &lt;objc/hashtable2.h&gt;
#import &quot;maptable.h&quot;
#import &quot;objc-private.h&quot;
#import &lt;objc/Object.h&gt;
#import &lt;objc/Protocol.h&gt;

#<span class="enscript-keyword">if</span> !defined(WIN32)
#include &lt;sys/time.h&gt;
#include &lt;sys/resource.h&gt;
#endif

OBJC_EXPORT Class		_objc_getNonexistentClass	(void);

#<span class="enscript-keyword">if</span> defined(NeXT_PDO) // GENERIC_OBJ_FILE
OBJC_EXPORT void		(*load_class_callback)		(Class, Category);
OBJC_EXPORT unsigned int	_objc_goff_headerCount		(void);
OBJC_EXPORT header_info *	_objc_goff_headerVector		(void);
#endif 

OBJC_EXPORT Class		getOriginalClassForPosingClass	(Class);

#<span class="enscript-keyword">if</span> defined(WIN32) || defined(__svr4__)
// Current Module Header
extern objcModHeader *		CMH;
#endif

/***********************************************************************
 * Constants <span class="enscript-type">and</span> macros internal to this module.
 **********************************************************************/

/* Turn on support <span class="enscript-keyword">for</span> literal string objects. */
#define LITERAL_STRING_OBJECTS

/***********************************************************************
 * Types internal to this module.
 **********************************************************************/

typedef struct _objc_unresolved_category
{
	struct _objc_unresolved_category *	next;
	struct objc_category *			<span class="enscript-type">cat</span>;
	long					<span class="enscript-type">version</span>;
} _objc_unresolved_category;

typedef struct _PendingClass
{
	struct objc_class * *			ref;
	struct objc_class *			classToSetUp;
	const <span class="enscript-type">char</span> *		nameof_superclass;
	int			<span class="enscript-type">version</span>;
	struct _PendingClass *	next;
} PendingClass;

/***********************************************************************
 * Exports.
 **********************************************************************/

// Mask <span class="enscript-type">which</span> specifies whether we are multi-threaded <span class="enscript-type">or</span> <span class="enscript-type">not</span>.
// A value of (-1) means single-threaded, 0 means multi-threaded. 
int		_objc_multithread_mask = (-1);

// Function to call when message sent to nil object.
void		(*_objc_msgNil)(id, SEL) = NULL;

// Function called after <span class="enscript-type">class</span> has been fixed up (MACH only)
void		(*callbackFunction)(Class, const <span class="enscript-type">char</span> *) = 0;

// Prototype <span class="enscript-keyword">for</span> <span class="enscript-keyword">function</span> passed to 
typedef void (*NilObjectMsgCallback) (id nilObject, SEL selector);

// Lock <span class="enscript-keyword">for</span> <span class="enscript-type">class</span> hashtable
OBJC_DECLARE_LOCK (classLock);

// Condition <span class="enscript-keyword">for</span> logging <span class="enscript-type">load</span> progress
int		rocketLaunchingDebug = -1;

/***********************************************************************
 * Function prototypes internal to this module.
 **********************************************************************/

static unsigned			classHash							(void * info, struct objc_class * data);
static int				classIsEqual						(void * info, struct objc_class * name, struct objc_class * cls);
static int				_objc_defaultClassHandler			(const <span class="enscript-type">char</span> * clsName);
static void				_objcTweakMethodListPointerForClass	(struct objc_class * cls);
static void				__objc_add_category					(struct objc_category * category, int <span class="enscript-type">version</span>);
static void				_objc_resolve_categories_for_class	(struct objc_class * cls);
static void				_objc_register_category				(struct objc_category *	<span class="enscript-type">cat</span>, long <span class="enscript-type">version</span>);
static void				_objc_add_categories_from_image		(header_info * hi);
#<span class="enscript-keyword">if</span> defined(__MACH__)
static const header_info * _headerForClass					(struct objc_class * cls);
#endif
static void				checkForPendingClassReferences		(struct objc_class * cls);
static PendingClass *	newPending							(void);
static NXMapTable *		pendingClassRefsMapTable			(void);
static NXHashTable *	_objc_get_classes_from_image		(NXHashTable * clsHash, header_info * hi);
static void				_objc_fixup_string_objects_for_image(header_info * hi);
static void				_objc_map_class_refs_for_image		(header_info * hi);
static void				map_selrefs							(SEL * sels, unsigned int cnt);
static void				map_method_descs					(struct objc_method_description_list * methods);
static void				_objc_fixup_protocol_objects_for_image	(header_info * hi);
#<span class="enscript-keyword">if</span> defined(__MACH__)
static void				_objc_bindModuleContainingCategory(Category <span class="enscript-type">cat</span>);
static void				_objc_bindModuleContainingClass(struct objc_class * cls);
#endif
static const <span class="enscript-type">char</span> *	libraryNameForMachHeader				(const headerType * themh);
static void				_objc_fixup_selector_refs			(const header_info * hi);
static void				_objc_call_loads_for_image			(header_info * header);
#<span class="enscript-keyword">if</span> defined(__MACH__)
static void				_objc_map_image_callback			(headerType * mh, unsigned long vmaddr_slide);
static void				_objc_link_module_callback			(NSModule <span class="enscript-type">mod</span>);
static void				_objc_unlink_module_callback		(NSModule <span class="enscript-type">mod</span>);
#endif

#<span class="enscript-keyword">if</span> defined(__MACH__)
extern int ptrace(int, int, int, int);
// ObjC is assigned the range 0xb000 - 0xbfff <span class="enscript-keyword">for</span> first parameter
#<span class="enscript-keyword">else</span>
#define ptrace(a, b, c, d) do {} <span class="enscript-keyword">while</span> (0)
#endif

/***********************************************************************
 * Static data internal to this module.
 **********************************************************************/

// System vectors created at runtime by reading the `__OBJC<span class="enscript-keyword">'</span> segments 
// that are a part of the application.
// We do <span class="enscript-type">not</span> lock these variables, since they are only <span class="enscript-type">set</span> during <span class="enscript-type">startup</span>. 
static header_info *	header_vector = 0;
static unsigned int		header_count = 0;
static unsigned int		header_vector_size = 0;

// Hash table of classes
static NXHashTable *		class_hash = 0;
static NXHashTablePrototype	classHashPrototype = 
{
	(unsigned (*) (const void *, const void *))			classHash, 
	(int (*)(const void *, const void *, const void *))	classIsEqual, 
	NXNoEffectFree, 0
};

// Function pointer objc_getClass calls through when <span class="enscript-type">class</span> is <span class="enscript-type">not</span> found
static int			(*objc_classHandler) (const <span class="enscript-type">char</span> *) = _objc_defaultClassHandler;

// Category <span class="enscript-type">and</span> <span class="enscript-type">class</span> registries
static NXMapTable *		category_hash = NULL;


static int						map_selectors_pended		= 0;

static NXMapTable *		pendingClassRefsMap = 0;

/***********************************************************************
 * objc_dump_class_hash.  Log names of <span class="enscript-type">all</span> known classes.
 **********************************************************************/
void	objc_dump_class_hash	       (void)
{
	NXHashTable *	table;
	unsigned		count;
	struct objc_class *	*		data;
	NXHashState		state;
	
	table = class_hash;
	count = 0;
	state = NXInitHashState (table);
	<span class="enscript-keyword">while</span> (NXNextHashState (table, &amp;state, (void **) &amp;data))
		printf (&quot;<span class="enscript-type">class</span> <span class="enscript-comment">%d: %s\n&quot;, ++count, (*data)-&gt;name);
</span>}

/***********************************************************************
 * classHash.
 **********************************************************************/
static unsigned		classHash	       (void *		info,
										struct objc_class *		data) 
{
	// Nil classes hash to zero
	<span class="enscript-keyword">if</span> (!data)
		<span class="enscript-keyword">return</span> 0;
	
	// Call through to <span class="enscript-type">real</span> hash <span class="enscript-keyword">function</span>
	<span class="enscript-keyword">return</span> _objc_strhash ((unsigned <span class="enscript-type">char</span> *) ((struct objc_class *) data)-&gt;name);
}

/***********************************************************************
 * classIsEqual.  Returns whether the <span class="enscript-type">class</span> names match.  If we ever
 * check <span class="enscript-type">more</span> than the name, routines like objc_lookUpClass have to
 * change as well.
 **********************************************************************/
static int		classIsEqual	       (void *		info,
										struct objc_class *		name,
										struct objc_class *		cls) 
{
	// Standard string comparison
	<span class="enscript-keyword">return</span> ((name-&gt;name<span class="enscript-type">[</span>0<span class="enscript-type">]</span> == cls-&gt;name<span class="enscript-type">[</span>0<span class="enscript-type">]</span>) &amp;&amp;
		(<span class="enscript-type">strcmp</span> (name-&gt;name, cls-&gt;name) == 0));
}

/***********************************************************************
 * _objc_init_class_hash.  Return the <span class="enscript-type">class</span> lookup table, create it <span class="enscript-keyword">if</span>
 * necessary.
 **********************************************************************/
void	_objc_init_class_hash	       (void)
{
	// Do nothing <span class="enscript-keyword">if</span> <span class="enscript-type">class</span> hash table already exists
	<span class="enscript-keyword">if</span> (class_hash)
		<span class="enscript-keyword">return</span>;
	
	// Provide a generous initial capacity to cut down on rehashes
	// at launch time.  A smallish Foundation+AppKit program will have
	// about 520 classes.  Larger apps (like IB <span class="enscript-type">or</span> WOB) have <span class="enscript-type">more</span> like
	// 800 classes.  Some customers have massive quantities of classes.
	// Foundation-only programs aren<span class="enscript-keyword">'</span>t likely to notice the ~6K loss.
	class_hash = NXCreateHashTableFromZone (classHashPrototype,
						1024,
						nil,
						_objc_create_zone ());
}

/***********************************************************************
 * objc_getClassList.  Return the known classes.
 **********************************************************************/
int objc_getClassList(Class *buffer, int bufferLen) {
	NXHashState state;
	struct objc_class * <span class="enscript-type">class</span>;
	int cnt, num;

	OBJC_LOCK(&amp;classLock);
	num = NXCountHashTable(class_hash);
	<span class="enscript-keyword">if</span> (NULL == buffer) {
		OBJC_UNLOCK(&amp;classLock);
		<span class="enscript-keyword">return</span> num;
	}
	cnt = 0;
	state = NXInitHashState(class_hash);
	<span class="enscript-keyword">while</span> (cnt &lt; num &amp;&amp; NXNextHashState(class_hash, &amp;state, (void **)&amp;<span class="enscript-type">class</span>)) {
		buffer<span class="enscript-type">[</span>cnt++<span class="enscript-type">]</span> = <span class="enscript-type">class</span>;
	}
	OBJC_UNLOCK(&amp;classLock);
	<span class="enscript-keyword">return</span> num;
}

/***********************************************************************
 * objc_getClasses.  Return <span class="enscript-type">class</span> lookup table.
 *
 * NOTE: This <span class="enscript-keyword">function</span> is very dangerous, since you cannot safely use
 * the hashtable without locking it, <span class="enscript-type">and</span> the lock is private! 
 **********************************************************************/
void *		objc_getClasses	       (void)
{
#<span class="enscript-keyword">if</span> defined(NeXT_PDO)
	// Make sure a hash table exists
	<span class="enscript-keyword">if</span> (!class_hash)
		_objc_init_class_hash ();
#endif

	// Return the <span class="enscript-type">class</span> lookup hash table
	<span class="enscript-keyword">return</span> class_hash;
}

/***********************************************************************
 * _objc_defaultClassHandler.  Default objc_classHandler.  Does nothing.
 **********************************************************************/
static int	_objc_defaultClassHandler      (const <span class="enscript-type">char</span> *	clsName)
{
	// Return zero so objc_getClass doesn<span class="enscript-keyword">'</span>t bother re-searching
	<span class="enscript-keyword">return</span> 0;
}

/***********************************************************************
 * objc_setClassHandler.  Set objc_classHandler to the specified value.
 *
 * NOTE: This should probably <span class="enscript-type">deal</span> with userSuppliedHandler being NULL,
 * because the objc_classHandler caller does <span class="enscript-type">not</span> check<span class="enscript-keyword">...</span> it would bus
 * <span class="enscript-keyword">error</span>.  It would make sense to handle NULL by restoring the default
 * handler.  Is anyone hacking with this, though?
 **********************************************************************/
void	objc_setClassHandler	(int	(*userSuppliedHandler) (const <span class="enscript-type">char</span> *))
{
	objc_classHandler = userSuppliedHandler;
}

/***********************************************************************
 * objc_getClass.  Return the id of the named <span class="enscript-type">class</span>.  If the <span class="enscript-type">class</span> does
 * <span class="enscript-type">not</span> <span class="enscript-type">exist</span>, call the objc_classHandler routine with the <span class="enscript-type">class</span> name.
 * If the objc_classHandler returns a non-zero value, <span class="enscript-type">try</span> once <span class="enscript-type">more</span> to
 * <span class="enscript-type">find</span> the <span class="enscript-type">class</span>.  Default objc_classHandler always returns zero.
 * objc_setClassHandler is how someone can install a non-default routine.
 **********************************************************************/
id		objc_getClass	       (const <span class="enscript-type">char</span> *	aClassName)
{ 
	struct objc_class	cls;
	id					ret;

	// Synchronize access to hash table
	OBJC_LOCK (&amp;classLock);
	
	// Check the hash table
	cls.name = aClassName;
	ret = (id) NXHashGet (class_hash, &amp;cls);
	OBJC_UNLOCK (&amp;classLock);
	
	// If <span class="enscript-type">not</span> found, go call objc_classHandler <span class="enscript-type">and</span> <span class="enscript-type">try</span> again
	<span class="enscript-keyword">if</span> (!ret &amp;&amp; (*objc_classHandler)(aClassName))
	{
		OBJC_LOCK (&amp;classLock);
		ret = (id) NXHashGet (class_hash, &amp;cls);
		OBJC_UNLOCK (&amp;classLock);
	}

	<span class="enscript-keyword">return</span> ret;
}

/***********************************************************************
 * objc_lookUpClass.  Return the id of the named <span class="enscript-type">class</span>.
 *
 * Formerly objc_getClassWithoutWarning ()
 **********************************************************************/
id		objc_lookUpClass       (const <span class="enscript-type">char</span> *	aClassName)
{ 
	struct objc_class	cls;
	id					ret;
	
	// Synchronize access to hash table
	OBJC_LOCK (&amp;classLock);

	// Check the hash table
	cls.name = aClassName;
	ret = (id) NXHashGet (class_hash, &amp;cls);
	
	// Desynchronize
	OBJC_UNLOCK (&amp;classLock);
	<span class="enscript-keyword">return</span> ret;
}

/***********************************************************************
 * objc_getMetaClass.  Return the id of the meta <span class="enscript-type">class</span> the named <span class="enscript-type">class</span>.
 **********************************************************************/
id		objc_getMetaClass       (const <span class="enscript-type">char</span> *	aClassName) 
{ 
	struct objc_class *	cls;
	
	cls = objc_getClass (aClassName);
	<span class="enscript-keyword">if</span> (!cls)
	{
		_objc_inform (&quot;<span class="enscript-type">class</span> `<span class="enscript-comment">%s' not linked into application&quot;, aClassName);
</span>		<span class="enscript-keyword">return</span> Nil;
	}

	<span class="enscript-keyword">return</span> cls-&gt;<span class="enscript-type">isa</span>;
}

/***********************************************************************
 * objc_addClass.  Add the specified <span class="enscript-type">class</span> to the table of known classes,
 * after doing a little verification <span class="enscript-type">and</span> fixup.
 **********************************************************************/
void		objc_addClass		(Class		cls) 
{
	// Synchronize access to hash table
	OBJC_LOCK (&amp;classLock);
	
	// Make sure both the <span class="enscript-type">class</span> <span class="enscript-type">and</span> the metaclass have caches!
	// Clear <span class="enscript-type">all</span> bits of the info fields except CLS_CLASS <span class="enscript-type">and</span> CLS_META.
	// Normally these bits are already <span class="enscript-keyword">clear</span> but <span class="enscript-keyword">if</span> someone tries to cons
	// up their own <span class="enscript-type">class</span> on the fly they might need to be cleared.
	<span class="enscript-keyword">if</span> (((struct objc_class *)cls)-&gt;cache == NULL)
	{
		((struct objc_class *)cls)-&gt;cache = (Cache) &amp;emptyCache;
		((struct objc_class *)cls)-&gt;info = CLS_CLASS;
	}
	
	<span class="enscript-keyword">if</span> (((struct objc_class *)cls)-&gt;<span class="enscript-type">isa</span>-&gt;cache == NULL)
	{
		((struct objc_class *)cls)-&gt;<span class="enscript-type">isa</span>-&gt;cache = (Cache) &amp;emptyCache;
		((struct objc_class *)cls)-&gt;<span class="enscript-type">isa</span>-&gt;info = CLS_META;
	}
	
	// Add the <span class="enscript-type">class</span> to the table
	(void) NXHashInsert (class_hash, cls);

	// Desynchronize
	OBJC_UNLOCK (&amp;classLock);
}

/***********************************************************************
 * _objcTweakMethodListPointerForClass.
 **********************************************************************/
static void	_objcTweakMethodListPointerForClass     (struct objc_class *	cls)
{
	struct objc_method_list *	originalList;
	const int					initialEntries = 4;
	int							mallocSize;
	struct objc_method_list **	ptr;
	
	// Remember existing list
	originalList = (struct objc_method_list *) cls-&gt;methodLists;
	
	// Allocate <span class="enscript-type">and</span> zero a method list array
	mallocSize   = sizeof(struct objc_method_list *) * initialEntries;
	ptr	     = (struct objc_method_list **) malloc_zone_calloc (_objc_create_zone (), 1, mallocSize);
	
	// Insert the existing list into the array
	ptr<span class="enscript-type">[</span>initialEntries - 1<span class="enscript-type">]</span> = END_OF_METHODS_LIST;
	ptr<span class="enscript-type">[</span>0<span class="enscript-type">]</span> = originalList;
	
	// Replace existing list with array
	((struct objc_class *)cls)-&gt;methodLists = ptr;
	((struct objc_class *)cls)-&gt;info |= CLS_METHOD_ARRAY;
	
	// Do the same thing to the meta-<span class="enscript-type">class</span>
	<span class="enscript-keyword">if</span> (((((struct objc_class *)cls)-&gt;info &amp; CLS_CLASS) != 0) &amp;&amp; cls-&gt;<span class="enscript-type">isa</span>)
		_objcTweakMethodListPointerForClass (cls-&gt;<span class="enscript-type">isa</span>);
}

/***********************************************************************
 * _objc_insertMethods.
 **********************************************************************/
void	_objc_insertMethods    (struct objc_method_list *	mlist,
								struct objc_method_list ***	list)
{
	struct objc_method_list **			ptr;
	volatile struct objc_method_list **	tempList;
	int									endIndex;
	int									oldSize;
	int									newSize;
	
	// Locate unused entry <span class="enscript-keyword">for</span> insertion point
	ptr = *list;
	<span class="enscript-keyword">while</span> ((*ptr != 0) &amp;&amp; (*ptr != END_OF_METHODS_LIST))
		ptr += 1;
	
	// If array is <span class="enscript-type">full</span>, <span class="enscript-type">double</span> it
	<span class="enscript-keyword">if</span> (*ptr == END_OF_METHODS_LIST)
	{
		// Calculate old <span class="enscript-type">and</span> new dimensions
		endIndex = ptr - *list;
		oldSize  = (endIndex + 1) * sizeof(void *);
		newSize  = oldSize + sizeof(struct objc_method_list *); // only increase by 1
		
		// Replace existing array with copy twice its <span class="enscript-type">size</span>
		tempList = (struct objc_method_list **) malloc_zone_realloc ((void *) _objc_create_zone (),
								      						   (void *) *list,
														       (size_t) newSize);
		*list = tempList;
		
		// Zero out addition part of new array
		bzero (&amp;((*list)<span class="enscript-type">[</span>endIndex<span class="enscript-type">]</span>), newSize - oldSize);
		
		// Place new <span class="enscript-keyword">end</span> marker
		(*list)<span class="enscript-type">[</span>(newSize/sizeof(void *)) - 1<span class="enscript-type">]</span> = END_OF_METHODS_LIST;
		
		// Insertion point corresponds to old array <span class="enscript-keyword">end</span>
		ptr = &amp;((*list)<span class="enscript-type">[</span>endIndex<span class="enscript-type">]</span>);
	}
	
	// Right shift existing entries by one 
	bcopy (*list, (*list) + 1, ((void *) ptr) - ((void *) *list));
	
	// Insert at method list at beginning of array
	**list = mlist;
}

/***********************************************************************
 * _objc_removeMethods.
 **********************************************************************/
void	_objc_removeMethods    (struct objc_method_list *	mlist,
								struct objc_method_list ***	list)
{
	struct objc_method_list **	ptr;
 
        // Locate list in the array 
        ptr = *list;
        <span class="enscript-keyword">while</span> (*ptr != mlist) {
                // <span class="enscript-type">fix</span> <span class="enscript-keyword">for</span> radar # 2538790
                <span class="enscript-keyword">if</span> ( *ptr == END_OF_METHODS_LIST ) <span class="enscript-keyword">return</span>;
                ptr += 1;
        }
 
        // Remove this entry 
        *ptr = 0;
  
        // Left shift the following entries
        <span class="enscript-keyword">while</span> (*(++ptr) != END_OF_METHODS_LIST)
                *(ptr-1) = *ptr;
        *(ptr-1) = 0;
}

/***********************************************************************
 * __objc_add_category.  Install the specified category<span class="enscript-keyword">'</span>s methods <span class="enscript-type">and</span>
 * protocols into the <span class="enscript-type">class</span> it augments.
 **********************************************************************/
static <span class="enscript-type">inline</span> void	__objc_add_category    (struct objc_category *	category,
											int						<span class="enscript-type">version</span>)
{
	struct objc_class *	cls;
	
	// Locate the <span class="enscript-type">class</span> that the category will extend
	cls = (struct objc_class *) objc_getClass (category-&gt;class_name);
	<span class="enscript-keyword">if</span> (!cls)
	{
		_objc_inform (&quot;unable to add category <span class="enscript-comment">%s...\n&quot;, category-&gt;category_name);
</span>		_objc_inform (&quot;<span class="enscript-type">class</span> `<span class="enscript-comment">%s' not linked into application\n&quot;, category-&gt;class_name);
</span>		<span class="enscript-keyword">return</span>;
	}

	// Augment instance methods
	<span class="enscript-keyword">if</span> (category-&gt;instance_methods)
		_objc_insertMethods (category-&gt;instance_methods, &amp;cls-&gt;methodLists);

	// Augment <span class="enscript-type">class</span> methods
	<span class="enscript-keyword">if</span> (category-&gt;class_methods)
		_objc_insertMethods (category-&gt;class_methods, &amp;cls-&gt;<span class="enscript-type">isa</span>-&gt;methodLists);

	// Augment protocols
	<span class="enscript-keyword">if</span> ((<span class="enscript-type">version</span> &gt;= 5) &amp;&amp; category-&gt;protocols)
	{
		<span class="enscript-keyword">if</span> (cls-&gt;<span class="enscript-type">isa</span>-&gt;<span class="enscript-type">version</span> &gt;= 5)
		{
			category-&gt;protocols-&gt;next = cls-&gt;protocols;
			cls-&gt;protocols	          = category-&gt;protocols;
			cls-&gt;<span class="enscript-type">isa</span>-&gt;protocols       = category-&gt;protocols;
		}
		<span class="enscript-keyword">else</span>
		{
			_objc_inform (&quot;unable to add protocols from category <span class="enscript-comment">%s...\n&quot;, category-&gt;category_name);
</span>			_objc_inform (&quot;<span class="enscript-type">class</span> `<span class="enscript-comment">%s' must be recompiled\n&quot;, category-&gt;class_name);
</span>		}
	}
	
#<span class="enscript-keyword">if</span> defined(NeXT_PDO) // GENERIC_OBJ_FILE
	// Call back
	<span class="enscript-keyword">if</span> (load_class_callback)
		(*load_class_callback) (cls, 0);
	
	// Call +finishLoading:: from the category<span class="enscript-keyword">'</span>s method list
	send_load_message_to_category (category, (void *) header_vector<span class="enscript-type">[</span>0<span class="enscript-type">]</span>.mhdr);
#endif
}

/***********************************************************************
 * _objc_add_category.  Install the specified category<span class="enscript-keyword">'</span>s methods into
 * the <span class="enscript-type">class</span> it augments, <span class="enscript-type">and</span> flush the class<span class="enscript-keyword">'</span> method cache.
 *
 * Private extern used by objc_loadModules ()
 **********************************************************************/
void	_objc_add_category     (struct objc_category *	category,
								int						<span class="enscript-type">version</span>)
{
	// Install the category<span class="enscript-keyword">'</span>s methods into its intended <span class="enscript-type">class</span>
	__objc_add_category (category, <span class="enscript-type">version</span>);
	
	// Flush caches so category<span class="enscript-keyword">'</span>s methods can <span class="enscript-type">get</span> called
	_objc_flush_caches (objc_lookUpClass (category-&gt;class_name));
}

/***********************************************************************
 * _objc_resolve_categories_for_class.  Install <span class="enscript-type">all</span> categories intended
 * <span class="enscript-keyword">for</span> the specified <span class="enscript-type">class</span>, in reverse order from the order in <span class="enscript-type">which</span> we
 * found the categories in the <span class="enscript-type">image</span>.
 **********************************************************************/
static void	_objc_resolve_categories_for_class  (struct objc_class *	cls)
{
	_objc_unresolved_category *	<span class="enscript-type">cat</span>;
	_objc_unresolved_category *	next;
	
	// Nothing to do <span class="enscript-keyword">if</span> there are no categories at <span class="enscript-type">all</span>
	<span class="enscript-keyword">if</span> (!category_hash)
		<span class="enscript-keyword">return</span>;
	
	// Locate <span class="enscript-type">and</span> remove first element in category list
	// associated with this <span class="enscript-type">class</span>
	<span class="enscript-type">cat</span> = NXMapRemove (category_hash, cls-&gt;name);
	
	// Traverse the list of categories, <span class="enscript-keyword">if</span> <span class="enscript-type">any</span>, registered <span class="enscript-keyword">for</span> this <span class="enscript-type">class</span>
	<span class="enscript-keyword">while</span> (<span class="enscript-type">cat</span>)
	{
		// Install the category
		_objc_add_category (<span class="enscript-type">cat</span>-&gt;<span class="enscript-type">cat</span>, <span class="enscript-type">cat</span>-&gt;<span class="enscript-type">version</span>);
		
		// Delink <span class="enscript-type">and</span> reclaim this registration
		next = <span class="enscript-type">cat</span>-&gt;next;
		free (<span class="enscript-type">cat</span>);
		<span class="enscript-type">cat</span> = next;
	}
}

/***********************************************************************
 * _objc_register_category.  Add the specified category to the registry
 * of categories to be installed later (once we know <span class="enscript-keyword">for</span> sure <span class="enscript-type">which</span>
 * classes we have).  If there are multiple categories on a given <span class="enscript-type">class</span>,
 * they will be processed in reverse order from the order in <span class="enscript-type">which</span> they
 * were found in the <span class="enscript-type">image</span>.
 **********************************************************************/
static void _objc_register_category    (struct objc_category *	<span class="enscript-type">cat</span>,
										long					<span class="enscript-type">version</span>)
{
	_objc_unresolved_category *	new_cat;
	_objc_unresolved_category *	old;
	
	
	// If the category<span class="enscript-keyword">'</span>s <span class="enscript-type">class</span> exists, just add the category
	<span class="enscript-keyword">if</span> (objc_lookUpClass (<span class="enscript-type">cat</span>-&gt;class_name))
	{
		_objc_add_category (<span class="enscript-type">cat</span>, <span class="enscript-type">version</span>);
		<span class="enscript-keyword">return</span>;
	}
	
	// Create category lookup table <span class="enscript-keyword">if</span> needed
	<span class="enscript-keyword">if</span> (!category_hash)
		category_hash = NXCreateMapTableFromZone (NXStrValueMapPrototype,
							  128,
							  _objc_create_zone ());
	
	// Locate an existing category, <span class="enscript-keyword">if</span> <span class="enscript-type">any</span>, <span class="enscript-keyword">for</span> the <span class="enscript-type">class</span>.  This is linked
	// after the new entry, so list is LIFO.
	old = NXMapGet (category_hash, <span class="enscript-type">cat</span>-&gt;class_name);
	
	// Register the category to be fixed up later
	new_cat = malloc_zone_malloc (_objc_create_zone (),
				sizeof(_objc_unresolved_category));
	new_cat-&gt;next    = old;
	new_cat-&gt;<span class="enscript-type">cat</span>     = <span class="enscript-type">cat</span>;
	new_cat-&gt;<span class="enscript-type">version</span> = <span class="enscript-type">version</span>;
	(void) NXMapInsert (category_hash, <span class="enscript-type">cat</span>-&gt;class_name , new_cat);
}

/***********************************************************************
 * _objc_add_categories_from_image.
 **********************************************************************/
static void _objc_add_categories_from_image (header_info *  hi)
{
	Module		mods;
	unsigned int	midx;
	
	// Major loop - process <span class="enscript-type">all</span> modules in the header
	mods = (Module) ((unsigned long) hi-&gt;mod_ptr + hi-&gt;image_slide);

//	ptrace(0xb120, hi-&gt;mod_count, 0, 0);

	<span class="enscript-keyword">for</span> (midx = 0; midx &lt; hi-&gt;mod_count; midx += 1)
	{
		unsigned int	index; 
		unsigned int	total; 
		
		// Nothing to do <span class="enscript-keyword">for</span> a module without a symbol table
		<span class="enscript-keyword">if</span> (mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab == NULL)
			continue;
		
		// Total entries in symbol table (<span class="enscript-type">class</span> entries followed
		// by category entries)
		total = mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;cls_def_cnt +
			mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;cat_def_cnt;
		
#<span class="enscript-keyword">if</span> defined(__MACH__)
		<span class="enscript-keyword">if</span> ((hi-&gt;mhdr-&gt;filetype == MH_DYLIB) ||
		    (hi-&gt;mhdr-&gt;filetype == MH_BUNDLE))
		{
			void **	defs;
			
			defs = mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;defs;

//			ptrace(0xb121, midx, mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;cls_def_cnt, mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;cat_def_cnt);

			<span class="enscript-keyword">for</span> (index = 0; index &lt; mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;cls_def_cnt; index += 1)
				_objc_bindModuleContainingClass (defs<span class="enscript-type">[</span>index<span class="enscript-type">]</span>);
			
			<span class="enscript-keyword">for</span> (index = mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;cls_def_cnt; index &lt; total; index += 1)
				_objc_bindModuleContainingCategory (defs<span class="enscript-type">[</span>index<span class="enscript-type">]</span>);

//			ptrace(0xb122, midx, 0, 0);
		}
#endif 
		
//		ptrace(0xb123, midx, mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;cat_def_cnt, 0);

		// Minor loop - register <span class="enscript-type">all</span> categories from given module
		<span class="enscript-keyword">for</span> (index = mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;cls_def_cnt; index &lt; total; index += 1)
		{
			_objc_register_category	(mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;defs<span class="enscript-type">[</span>index<span class="enscript-type">]</span>,
						 mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.<span class="enscript-type">version</span>);
		}

//		ptrace(0xb124, midx, 0, 0);
	}

//	ptrace(0xb12f, 0, 0, 0);
}

#<span class="enscript-keyword">if</span> defined(__MACH__)
/***********************************************************************
 * _headerForClass.
 **********************************************************************/
static const header_info *  _headerForClass     (struct objc_class *	cls)
{
	const struct segment_command *	objcSeg;
	unsigned int					hidx;
	unsigned int					<span class="enscript-type">size</span>;
	unsigned long					vmaddrPlus;
	
	// Check <span class="enscript-type">all</span> headers in the vector
	<span class="enscript-keyword">for</span> (hidx = 0; hidx &lt; header_count; hidx += 1)
	{
		// Locate header data, <span class="enscript-keyword">if</span> <span class="enscript-type">any</span>
		objcSeg = _getObjcHeaderData ((headerType *) header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.mhdr, &amp;<span class="enscript-type">size</span>);
		<span class="enscript-keyword">if</span> (!objcSeg)
			continue;

		// Is the <span class="enscript-type">class</span> in this header?
		vmaddrPlus = (unsigned long) objcSeg-&gt;vmaddr + header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.image_slide;
		<span class="enscript-keyword">if</span> ((vmaddrPlus &lt;= (unsigned long) cls) &amp;&amp;
		    ((unsigned long) cls &lt; (vmaddrPlus + <span class="enscript-type">size</span>)))
			<span class="enscript-keyword">return</span> &amp;(header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>);
	}
	
	// Not found
	<span class="enscript-keyword">return</span> 0;
}
#endif // __MACH__

/***********************************************************************
 * _nameForHeader.
 **********************************************************************/
const <span class="enscript-type">char</span> *	_nameForHeader	       (const headerType *	header)
{
	<span class="enscript-keyword">return</span> _getObjcHeaderName ((headerType *) header);
}

/***********************************************************************
 * checkForPendingClassReferences.  Complete <span class="enscript-type">any</span> fixups registered <span class="enscript-keyword">for</span>
 * this <span class="enscript-type">class</span>.
 **********************************************************************/
static void	checkForPendingClassReferences	       (struct objc_class *	cls)
{
	PendingClass *	pending;

	// Nothing to do <span class="enscript-keyword">if</span> there are no pending classes
	<span class="enscript-keyword">if</span> (!pendingClassRefsMap)
		<span class="enscript-keyword">return</span>;
	
	// Get pending list <span class="enscript-keyword">for</span> this <span class="enscript-type">class</span>
	pending = NXMapGet (pendingClassRefsMap, cls-&gt;name);
	<span class="enscript-keyword">if</span> (!pending)
		<span class="enscript-keyword">return</span>;
	
	// Remove the list from the table
	(void) NXMapRemove (pendingClassRefsMap, cls-&gt;name);
	
	// Process <span class="enscript-type">all</span> elements in the list
	<span class="enscript-keyword">while</span> (pending)
	{
		PendingClass *	next;
		
		// Remember follower <span class="enscript-keyword">for</span> loop
		next = pending-&gt;next;
		
		// Fill in a pointer to Class 
		// (satisfies caller of objc_pendClassReference)
		<span class="enscript-keyword">if</span> (pending-&gt;ref)
			*pending-&gt;ref = objc_getClass (cls-&gt;name);

		// Fill in super, <span class="enscript-type">isa</span>, cache, <span class="enscript-type">and</span> <span class="enscript-type">version</span> <span class="enscript-keyword">for</span> the <span class="enscript-type">class</span>
		// <span class="enscript-type">and</span> its meta-<span class="enscript-type">class</span>
		// (satisfies caller of objc_pendClassInstallation)
		// NOTE: There must be no <span class="enscript-type">more</span> than one of these <span class="enscript-keyword">for</span>
		// <span class="enscript-type">any</span> given classToSetUp
		<span class="enscript-keyword">if</span> (pending-&gt;classToSetUp)
		{
			struct objc_class *	fixCls;
		
			// Locate the Class to be fixed up
			fixCls = pending-&gt;classToSetUp;
			
			// Set up super <span class="enscript-type">class</span> fields with names to be replaced by pointers
			fixCls-&gt;super_class      = (struct objc_class *) pending-&gt;nameof_superclass;
			fixCls-&gt;<span class="enscript-type">isa</span>-&gt;super_class = (struct objc_class *) pending-&gt;nameof_superclass;
			
			// Fix up <span class="enscript-type">class</span> pointers, <span class="enscript-type">version</span>, <span class="enscript-type">and</span> cache pointers
			_class_install_relationships (fixCls, pending-&gt;<span class="enscript-type">version</span>);
		}
		
		// Reclaim the element
		free (pending);
		
		// Move on
		pending = next;
	}
}

/***********************************************************************
 * newPending.  Allocate <span class="enscript-type">and</span> zero a PendingClass structure.
 **********************************************************************/
static <span class="enscript-type">inline</span> PendingClass *	newPending	       (void)
{
	PendingClass *	pending;
	
	pending = (PendingClass *) malloc_zone_calloc (_objc_create_zone (), 1, sizeof(PendingClass));
	
	<span class="enscript-keyword">return</span> pending;
}

/***********************************************************************
 * pendingClassRefsMapTable.  Return a pointer to the lookup table <span class="enscript-keyword">for</span>
 * pending classes.
 **********************************************************************/
static <span class="enscript-type">inline</span> NXMapTable *	pendingClassRefsMapTable    (void)
{
	// Allocate table <span class="enscript-keyword">if</span> needed
	<span class="enscript-keyword">if</span> (!pendingClassRefsMap)
		pendingClassRefsMap = NXCreateMapTableFromZone (NXStrValueMapPrototype, 10, _objc_create_zone ());
	
	// Return table pointer
	<span class="enscript-keyword">return</span> pendingClassRefsMap;
}

/***********************************************************************
 * objc_pendClassReference.  Register the specified <span class="enscript-type">class</span> pointer (ref)
 * to be filled in later with a pointer to the <span class="enscript-type">class</span> having the specified
 * name.
 **********************************************************************/
void	objc_pendClassReference	       (const <span class="enscript-type">char</span> *	className,
										struct objc_class * *		ref)
{
	NXMapTable *		table;
	PendingClass *		pending;
	
	// Create <span class="enscript-type">and</span>/<span class="enscript-type">or</span> locate pending <span class="enscript-type">class</span> lookup table
	table = pendingClassRefsMapTable ();

	// Create entry containing the <span class="enscript-type">class</span> reference
	pending = newPending ();
	pending-&gt;ref = ref;
	
	// Link new entry into head of list of entries <span class="enscript-keyword">for</span> this <span class="enscript-type">class</span>
	pending-&gt;next = NXMapGet (pendingClassRefsMap, className);
	
	// (Re)place entry list in the table
	(void) NXMapInsert (table, className, pending);
}

/***********************************************************************
 * objc_pendClassInstallation.  Register the specified <span class="enscript-type">class</span> to have its
 * super <span class="enscript-type">class</span> pointers filled in later because the superclass is <span class="enscript-type">not</span>
 * yet found.
 **********************************************************************/
void	objc_pendClassInstallation     (struct objc_class *	cls,
										int		<span class="enscript-type">version</span>)
{
	NXMapTable *		table;
	PendingClass *		pending;
	
	// Create <span class="enscript-type">and</span>/<span class="enscript-type">or</span> locate pending <span class="enscript-type">class</span> lookup table
	table = pendingClassRefsMapTable ();

	// Create entry referring to this <span class="enscript-type">class</span>
	pending = newPending ();
	pending-&gt;classToSetUp	   = cls;
	pending-&gt;nameof_superclass = (const <span class="enscript-type">char</span> *) cls-&gt;super_class;
	pending-&gt;<span class="enscript-type">version</span>	   = <span class="enscript-type">version</span>;
	
	// Link new entry into head of list of entries <span class="enscript-keyword">for</span> this <span class="enscript-type">class</span>
	pending-&gt;next		   = NXMapGet (pendingClassRefsMap, cls-&gt;super_class);
	
	// (Re)place entry list in the table
	(void) NXMapInsert (table, cls-&gt;super_class, pending);
}

/***********************************************************************
 * _objc_get_classes_from_image.  Install <span class="enscript-type">all</span> classes contained in the
 * specified <span class="enscript-type">image</span>.
 **********************************************************************/
static NXHashTable *	_objc_get_classes_from_image   (NXHashTable *	clsHash,
														header_info *	hi)
{
	unsigned int	index;
	unsigned int	midx;
	Module			mods;
	
	// Major loop - process <span class="enscript-type">all</span> modules in the <span class="enscript-type">image</span>
	mods = (Module) ((unsigned long) hi-&gt;mod_ptr + hi-&gt;image_slide);
	<span class="enscript-keyword">for</span> (midx = 0; midx &lt; hi-&gt;mod_count; midx += 1)
	{
		// Skip module containing no classes
		<span class="enscript-keyword">if</span> (mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab == NULL)
			continue;
		
		// Minor loop - process <span class="enscript-type">all</span> the classes in given module
		<span class="enscript-keyword">for</span> (index = 0; index &lt; mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;cls_def_cnt; index += 1)
		{
		struct objc_class *	oldCls;
		struct objc_class *	newCls;
			
			// Locate the <span class="enscript-type">class</span> description pointer
			newCls = mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.symtab-&gt;defs<span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
			
			// Convert old style method list to the new style
			_objcTweakMethodListPointerForClass (newCls);

			oldCls = NXHashInsert (clsHash, newCls);

			// Non-Nil oldCls is a <span class="enscript-type">class</span> that NXHashInsert just
			// bumped from table because it has the same name
			// as newCls
			<span class="enscript-keyword">if</span> (oldCls)
			{
#<span class="enscript-keyword">if</span> defined(__MACH__)
				const header_info *	oldHeader;
				const header_info *	newHeader;
				const <span class="enscript-type">char</span> *		oldName;
				const <span class="enscript-type">char</span> *		newName;

				// Log the duplication
				oldHeader = _headerForClass (oldCls);
				newHeader = _headerForClass (newCls);
				oldName   = _nameForHeader  (oldHeader-&gt;mhdr);
				newName   = _nameForHeader  (newHeader-&gt;mhdr);
				_objc_inform (&quot;Both <span class="enscript-comment">%s and %s have implementations of class %s.&quot;,
</span>								oldName, newName, oldCls-&gt;name);				   
				_objc_inform (&quot;Using implementation from <span class="enscript-comment">%s.&quot;, newName);
</span>#endif

				// Use the chosen <span class="enscript-type">class</span>
				// NOTE: Isn<span class="enscript-keyword">'</span>t this a NOP?
				newCls = objc_lookUpClass (oldCls-&gt;name);
			}
			
			// Unless newCls was a duplicate, <span class="enscript-type">and</span> we chose the
			// existing one instead, <span class="enscript-type">set</span> the <span class="enscript-type">version</span> in the meta-<span class="enscript-type">class</span>
			<span class="enscript-keyword">if</span> (newCls != oldCls)
				newCls-&gt;<span class="enscript-type">isa</span>-&gt;<span class="enscript-type">version</span> = mods<span class="enscript-type">[</span>midx<span class="enscript-type">]</span>.<span class="enscript-type">version</span>;

			// Install new categories intended <span class="enscript-keyword">for</span> this <span class="enscript-type">class</span>
			// NOTE: But, <span class="enscript-keyword">if</span> we displaced an existing &quot;isEqual&quot;
			// <span class="enscript-type">class</span>, the categories have already been installed
			// on an old <span class="enscript-type">class</span> <span class="enscript-type">and</span> are gone from the registry!!
			_objc_resolve_categories_for_class (newCls);
			
			// Resolve (a) pointers to the named <span class="enscript-type">class</span>, <span class="enscript-type">and</span>/<span class="enscript-type">or</span>
			// (b) the super_class, cache, <span class="enscript-type">and</span> <span class="enscript-type">version</span>
			// fields of newCls <span class="enscript-type">and</span> its meta-<span class="enscript-type">class</span>
			// NOTE: But, <span class="enscript-keyword">if</span> we displaced an existing &quot;isEqual&quot;
			// <span class="enscript-type">class</span>, this has already been done<span class="enscript-keyword">...</span> with an
			// old-<span class="enscript-type">now</span>-&quot;unused&quot; <span class="enscript-type">class</span>!!
			checkForPendingClassReferences (newCls);
			
#<span class="enscript-keyword">if</span> defined(NeXT_PDO) // GENERIC_OBJ_FILE
			// Invoke registered callback
			<span class="enscript-keyword">if</span> (load_class_callback)
				(*load_class_callback) (newCls, 0);
			
			// Call +finishLoading:: from the class<span class="enscript-keyword">'</span> method list
			send_load_message_to_class (newCls, (headerType *) hi-&gt;mhdr);
#endif
		}
	}
	
	// Return the table the caller passed
	<span class="enscript-keyword">return</span> clsHash;
}

/***********************************************************************
 * _objc_fixup_string_objects_for_image.  Initialize the <span class="enscript-type">isa</span> pointers
 * of <span class="enscript-type">all</span> NSConstantString objects.
 **********************************************************************/
static void	_objc_fixup_string_objects_for_image   (header_info *	hi)
{
	unsigned int				<span class="enscript-type">size</span>;
	OBJC_CONSTANT_STRING_PTR	section;
	struct objc_class *						constantStringClass;
	unsigned int				index;
	
	// Locate section holding string objects
	section = _getObjcStringObjects ((headerType *) hi-&gt;mhdr, &amp;<span class="enscript-type">size</span>);
	<span class="enscript-keyword">if</span> (!section || !<span class="enscript-type">size</span>)
		<span class="enscript-keyword">return</span>;
	section = (OBJC_CONSTANT_STRING_PTR) ((unsigned long) section + hi-&gt;image_slide);
#<span class="enscript-keyword">if</span> defined(NeXT_PDO) // GENERIC_OBJ_FILE
	<span class="enscript-keyword">if</span> (!(*section))
		<span class="enscript-keyword">return</span>;
#endif

	// Luckily NXConstantString is the same <span class="enscript-type">size</span> as NSConstantString
	constantStringClass = objc_getClass (&quot;NSConstantString&quot;);
	
	// Process each string object in the section
	<span class="enscript-keyword">for</span> (index = 0; index &lt; <span class="enscript-type">size</span>; index += 1)
	{
		struct objc_class * *		isaptr;
		
		isaptr = (struct objc_class * *) OBJC_CONSTANT_STRING_DEREF section<span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
		<span class="enscript-keyword">if</span> (*isaptr == 0)
			*isaptr = constantStringClass;
	}
}

/***********************************************************************
 * _objc_map_class_refs_for_image.  Convert the <span class="enscript-type">class</span> ref entries from
 * a <span class="enscript-type">class</span> name string pointer to a <span class="enscript-type">class</span> pointer.  If the <span class="enscript-type">class</span> does
 * <span class="enscript-type">not</span> yet <span class="enscript-type">exist</span>, the reference is added to a list of pending references
 * to be fixed up at a later <span class="enscript-type">date</span>.
 **********************************************************************/
static void _objc_map_class_refs_for_image (header_info * hi)
{
	struct objc_class * *			cls_refs;
	unsigned int	<span class="enscript-type">size</span>;
	unsigned int	index;
	
	// Locate <span class="enscript-type">class</span> refs in <span class="enscript-type">image</span>
	cls_refs = _getObjcClassRefs ((headerType *) hi-&gt;mhdr, &amp;<span class="enscript-type">size</span>);
	<span class="enscript-keyword">if</span> (!cls_refs)
		<span class="enscript-keyword">return</span>;
	cls_refs = (struct objc_class * *) ((unsigned long) cls_refs + hi-&gt;image_slide);
	
	// Process each <span class="enscript-type">class</span> ref
	<span class="enscript-keyword">for</span> (index = 0; index &lt; <span class="enscript-type">size</span>; index += 1)
	{
		const <span class="enscript-type">char</span> *	ref;
		struct objc_class *		cls;
		
		// Get ref to convert from name string to <span class="enscript-type">class</span> pointer
		ref = (const <span class="enscript-type">char</span> *) cls_refs<span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
		
		// Get pointer to <span class="enscript-type">class</span> of this name
		cls = (struct objc_class *)objc_lookUpClass (ref);
		
		// If <span class="enscript-type">class</span> isn<span class="enscript-keyword">'</span>t there yet, use pending mechanism
		<span class="enscript-keyword">if</span> (!cls)
		{
			// Register this ref to be <span class="enscript-type">set</span> later
			objc_pendClassReference (ref, &amp;cls_refs<span class="enscript-type">[</span>index<span class="enscript-type">]</span>);
			
			// Use place-holder <span class="enscript-type">class</span>
			cls_refs<span class="enscript-type">[</span>index<span class="enscript-type">]</span> = _objc_getNonexistentClass ();
		}
		
		// Replace name string pointer with <span class="enscript-type">class</span> pointer
		<span class="enscript-keyword">else</span>
			cls_refs<span class="enscript-type">[</span>index<span class="enscript-type">]</span> = cls;
	}
}

/***********************************************************************
 * map_selrefs.  Register each selector in the specified array.  If a
 * given selector is already registered, update this array to point to
 * the registered selector string.
 **********************************************************************/
static <span class="enscript-type">inline</span> void	map_selrefs    (SEL *			sels,
									unsigned int	cnt)
{ 
	unsigned int	index;
	
	// Process each selector
	<span class="enscript-keyword">for</span> (index = 0; index &lt; cnt; index += 1)
	{
		SEL	sel;
		
		// Lookup pointer to uniqued string
		sel = sel_registerNameNoCopy ((const <span class="enscript-type">char</span> *) sels<span class="enscript-type">[</span>index<span class="enscript-type">]</span>);

		// Replace this selector with uniqued one (avoid
		// modifying the VM page <span class="enscript-keyword">if</span> this would be a NOP)
		<span class="enscript-keyword">if</span> (sels<span class="enscript-type">[</span>index<span class="enscript-type">]</span> != sel)
			sels<span class="enscript-type">[</span>index<span class="enscript-type">]</span> = sel;
	}
}


/***********************************************************************
 * map_method_descs.  For each method in the specified method list,
 * replace the name pointer with a uniqued selector.
 **********************************************************************/
static void  map_method_descs (struct objc_method_description_list * methods)
{
	unsigned int	index;
	
	// Process each method
	<span class="enscript-keyword">for</span> (index = 0; index &lt; methods-&gt;count; index += 1)
	{
		struct objc_method_description *	method;
		SEL					sel;
		
		// Get method entry to <span class="enscript-type">fix</span> up
		method = &amp;methods-&gt;list<span class="enscript-type">[</span>index<span class="enscript-type">]</span>;

		// Lookup pointer to uniqued string
		sel = sel_registerNameNoCopy ((const <span class="enscript-type">char</span> *) method-&gt;name);

		// Replace this selector with uniqued one (avoid
		// modifying the VM page <span class="enscript-keyword">if</span> this would be a NOP)
		<span class="enscript-keyword">if</span> (method-&gt;name != sel)
			method-&gt;name = sel;
	}		  
}

/***********************************************************************
 * _fixup.
 **********************************************************************/
@interface Protocol(RuntimePrivate)
+ _fixup: (OBJC_PROTOCOL_PTR)protos numElements: (int) nentries;
@<span class="enscript-keyword">end</span>

/***********************************************************************
 * _objc_fixup_protocol_objects_for_image.  For each protocol in the
 * specified <span class="enscript-type">image</span>, selectorize the method names <span class="enscript-type">and</span> call +_fixup.
 **********************************************************************/
static void _objc_fixup_protocol_objects_for_image (header_info * hi)
{
	unsigned int		<span class="enscript-type">size</span>;
	OBJC_PROTOCOL_PTR	protos;
	unsigned int		index;
	
	// Locate protocals in the <span class="enscript-type">image</span>
	protos = (OBJC_PROTOCOL_PTR) _getObjcProtocols ((headerType *) hi-&gt;mhdr, &amp;<span class="enscript-type">size</span>);
	<span class="enscript-keyword">if</span> (!protos)
		<span class="enscript-keyword">return</span>;
	
	// Apply the slide bias
	protos = (OBJC_PROTOCOL_PTR) ((unsigned long) protos + hi-&gt;image_slide);
	
	// Process each protocol
	<span class="enscript-keyword">for</span> (index = 0; index &lt; <span class="enscript-type">size</span>; index += 1)
	{
		// Selectorize the instance methods
		<span class="enscript-keyword">if</span> (protos<span class="enscript-type">[</span>index<span class="enscript-type">]</span> OBJC_PROTOCOL_DEREF instance_methods)
			map_method_descs (protos<span class="enscript-type">[</span>index<span class="enscript-type">]</span> OBJC_PROTOCOL_DEREF instance_methods);
		
		// Selectorize the <span class="enscript-type">class</span> methods
		<span class="enscript-keyword">if</span> (protos<span class="enscript-type">[</span>index<span class="enscript-type">]</span> OBJC_PROTOCOL_DEREF class_methods)
			map_method_descs (protos<span class="enscript-type">[</span>index<span class="enscript-type">]</span> OBJC_PROTOCOL_DEREF class_methods);
	}
	
	// Invoke Protocol <span class="enscript-type">class</span> method to <span class="enscript-type">fix</span> up the protocol
	<span class="enscript-type">[</span>Protocol _fixup:(OBJC_PROTOCOL_PTR)protos numElements:<span class="enscript-type">size</span><span class="enscript-type">]</span>;
}

/***********************************************************************
 * _objc_headerVector.  Build the header vector, sorting it as
 * _objc_map_selectors () expects.
 **********************************************************************/
header_info *	_objc_headerVector (const headerType * const *	machhdrs)
{
	unsigned int	hidx;
	header_info *	hdrVec;
	
#<span class="enscript-keyword">if</span> defined(__MACH__) // <span class="enscript-type">not</span> GENERIC_OBJ_FILE
	// Take advatage of our previous work
	<span class="enscript-keyword">if</span> (header_vector)
		<span class="enscript-keyword">return</span> header_vector;
#<span class="enscript-keyword">else</span> // GENERIC_OBJ_FILE
	// If no headers specified, <span class="enscript-type">vectorize</span> generically
	<span class="enscript-keyword">if</span> (!machhdrs)
		<span class="enscript-keyword">return</span> _objc_goff_headerVector ();
	
	// Start from scratch
	header_count = 0;
#endif
	
	// Count headers
	<span class="enscript-keyword">for</span> (hidx = 0; machhdrs<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>; hidx += 1)
		header_count += 1;

	header_vector_size = header_count * 3; // very big

	// Allocate vector large enough to have entries <span class="enscript-keyword">for</span> <span class="enscript-type">all</span> of them
	hdrVec = malloc_zone_malloc  (_objc_create_zone (),
				header_vector_size * sizeof(header_info));
	<span class="enscript-keyword">if</span> (!hdrVec)
		_objc_fatal (&quot;unable to allocate module vector&quot;);
	
	// Fill vector entry <span class="enscript-keyword">for</span> each header
	<span class="enscript-keyword">for</span> (hidx = 0; hidx &lt; header_count; hidx += 1)
	{
		int	<span class="enscript-type">size</span>;
#<span class="enscript-keyword">if</span> defined(__MACH__)
		const struct segment_command *	objcSeg = NULL;
#endif
	
		hdrVec<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.mhdr	 = machhdrs<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>;
		hdrVec<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.image_slide = 0;
		hdrVec<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.mod_ptr	 = _getObjcModules ((headerType *) machhdrs<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>, &amp;<span class="enscript-type">size</span>);
		hdrVec<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.mod_count	 = <span class="enscript-type">size</span>;
		hdrVec<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.objcSize    = 0;
	
#<span class="enscript-keyword">if</span> defined(__MACH__) // <span class="enscript-type">not</span> GENERIC_OBJ_FILE
		objcSeg = (struct segment_command *) _getObjcHeaderData ((headerType *) machhdrs<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>, &amp;<span class="enscript-type">size</span>);
		<span class="enscript-keyword">if</span> (objcSeg)
			hdrVec<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.objcSize = ((struct segment_command *) objcSeg)-&gt;filesize;
#endif
	}
	
	<span class="enscript-keyword">return</span> hdrVec;
}

#<span class="enscript-keyword">if</span> defined(__MACH__)
void _objc_bindModuleContainingList() {
/* We define this <span class="enscript-keyword">for</span> backwards binary compat with things <span class="enscript-type">which</span> should <span class="enscript-type">not</span>
 * have been using it (cough OmniWeb), but <span class="enscript-type">now</span> it does nothing <span class="enscript-keyword">for</span> them.
 */
}

/***********************************************************************
 * _objc_bindModuleContainingCategory.  Bind the module containing the
 * category.
 **********************************************************************/
static void  _objc_bindModuleContainingCategory   (Category	<span class="enscript-type">cat</span>)
{
	<span class="enscript-type">char</span> *			class_name;
	<span class="enscript-type">char</span> *			category_name;
	<span class="enscript-type">char</span> *			name;
        <span class="enscript-type">char</span>                    tmp_buf<span class="enscript-type">[</span>128<span class="enscript-type">]</span>;
        unsigned int            name_len;

	// Bind &quot;.objc_category_name_&lt;classname&gt;_&lt;categoryname&gt;&quot;,
	// where &lt;classname&gt; is the <span class="enscript-type">class</span> name with the leading
	// <span class="enscript-string">'%'</span>s stripped.
	class_name    = <span class="enscript-type">cat</span>-&gt;class_name;
	category_name = <span class="enscript-type">cat</span>-&gt;category_name;
        name_len      = strlen(class_name) + strlen(category_name) + 30;
        <span class="enscript-keyword">if</span> ( name_len &gt; 128 )
	    name = malloc(name_len);
        <span class="enscript-keyword">else</span>
            name = tmp_buf;
	<span class="enscript-keyword">while</span> (*class_name == <span class="enscript-string">'%'</span>)
		class_name += 1;
	strcpy (name, &quot;.objc_category_name_&quot;);
	<span class="enscript-type">strcat</span> (name, class_name);
	<span class="enscript-type">strcat</span> (name, &quot;_&quot;);
	<span class="enscript-type">strcat</span> (name, category_name);
	<span class="enscript-keyword">if</span> (NSIsSymbolNameDefined(name)) _dyld_lookup_and_bind_objc(name, 0, 0);
        <span class="enscript-keyword">if</span> ( name != tmp_buf )
            free(name);
}

/***********************************************************************
 * _objc_bindModuleContainingClass.  Bind the module containing the
 * <span class="enscript-type">class</span>.
 **********************************************************************/
static void _objc_bindModuleContainingClass (struct objc_class * cls)
{
	struct objc_method_list *	mList;
	const <span class="enscript-type">char</span> *	class_name;
	<span class="enscript-type">char</span> *			name;
        <span class="enscript-type">char</span>                    tmp_buf<span class="enscript-type">[</span>128<span class="enscript-type">]</span>;
        unsigned int            name_len;
	
	// Use the <span class="enscript-type">real</span> <span class="enscript-type">class</span> behind the poser
	<span class="enscript-keyword">if</span> (CLS_GETINFO (cls, CLS_POSING))
		cls = getOriginalClassForPosingClass (cls);

	// Bind &quot;.objc_class_name_&lt;classname&gt;&quot;, where &lt;classname&gt;
	// is the <span class="enscript-type">class</span> name with the leading <span class="enscript-string">'%'</span>s stripped.
	class_name = cls-&gt;name;
        name_len   = strlen(class_name) + 20;
        <span class="enscript-keyword">if</span> ( name_len &gt; 128 )
	    name = malloc(name_len);
        <span class="enscript-keyword">else</span>
            name = tmp_buf;
	<span class="enscript-keyword">while</span> (*class_name == <span class="enscript-string">'%'</span>)
		class_name += 1;
	strcpy (name, &quot;.objc_class_name_&quot;);
	<span class="enscript-type">strcat</span> (name, class_name);
	<span class="enscript-keyword">if</span> (NSIsSymbolNameDefined(name)) _dyld_lookup_and_bind_objc(name, 0, 0);
        <span class="enscript-keyword">if</span> ( name != tmp_buf )
            free(name);
}
#endif // __MACH__
	
/***********************************************************************
 * _objc_headerCount.  Return the currently known number of `__OBJC<span class="enscript-keyword">'</span>
 * segments that are a part of the application
 **********************************************************************/
unsigned int	_objc_headerCount	       (void)
{
#<span class="enscript-keyword">if</span> defined(__MACH__) // <span class="enscript-type">not</span> GENERIC_OBJ_FILE
	<span class="enscript-keyword">return</span> header_count;
#<span class="enscript-keyword">else</span>
	<span class="enscript-keyword">return</span> _objc_goff_headerCount ();
#endif
}

/***********************************************************************
 * _objc_addHeader.
 *
 * NOTE: Yet another wildly inefficient routine.
 **********************************************************************/
void	_objc_addHeader	       (const headerType *	header,
								unsigned long		vmaddr_slide)
{
	// Account <span class="enscript-keyword">for</span> addition
	header_count += 1;
	
	// Create vector table <span class="enscript-keyword">if</span> needed
	<span class="enscript-keyword">if</span> (header_vector == 0)
	{
		header_vector_size = 100;
		header_vector = malloc_zone_malloc (_objc_create_zone (), 
					      header_vector_size * sizeof(header_info));
#<span class="enscript-keyword">if</span> defined(WIN32) || defined(__svr4__)
		bzero (header_vector, (header_vector_size * sizeof(header_info)));
#endif
	}
	
	
	// Malloc a new vector table one bigger than before
	<span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> (header_count &gt; header_vector_size)
	{
		void *	old;
	
		header_vector_size *= 2;	
		old = (void *) header_vector;
		header_vector = malloc_zone_malloc (_objc_create_zone (),
					      header_vector_size * sizeof(header_info));
	
#<span class="enscript-keyword">if</span> defined(WIN32) || defined(__svr4__)
		bzero (header_vector, (header_vector_size * sizeof(header_info)));
#endif
		memcpy ((void *) header_vector, old, (header_count - 1) * sizeof(header_info));
		malloc_zone_free (_objc_create_zone (), old);
	}
	
	// Set up the new vector entry
	header_vector<span class="enscript-type">[</span>header_count - 1<span class="enscript-type">]</span>.mhdr		= header;
	header_vector<span class="enscript-type">[</span>header_count - 1<span class="enscript-type">]</span>.mod_ptr		= NULL;
	header_vector<span class="enscript-type">[</span>header_count - 1<span class="enscript-type">]</span>.mod_count	= 0;
	header_vector<span class="enscript-type">[</span>header_count - 1<span class="enscript-type">]</span>.image_slide	= vmaddr_slide;
	header_vector<span class="enscript-type">[</span>header_count - 1<span class="enscript-type">]</span>.objcSize	= 0;
}

/***********************************************************************
 * libraryNameForMachHeader.
**********************************************************************/
static const <span class="enscript-type">char</span> *	libraryNameForMachHeader  (const headerType * themh)
{
#<span class="enscript-keyword">if</span> defined(NeXT_PDO)
	<span class="enscript-keyword">return</span> &quot;&quot;;
#<span class="enscript-keyword">else</span>
	unsigned long	index;
	unsigned long	imageCount;
	headerType *	mh;
	
	// Search images <span class="enscript-keyword">for</span> matching <span class="enscript-type">type</span>
	imageCount = _dyld_image_count ();
	<span class="enscript-keyword">for</span> (index = 0; index &lt; imageCount ; index += 1)
	{
		// Return name of <span class="enscript-type">image</span> with matching <span class="enscript-type">type</span>
		mh = _dyld_get_image_header (index);
		<span class="enscript-keyword">if</span> (mh == themh)
			<span class="enscript-keyword">return</span> _dyld_get_image_name (index);
	}
	
	// Not found
	<span class="enscript-keyword">return</span> 0;
#endif
}

/***********************************************************************
 * _objc_fixup_selector_refs.  Register <span class="enscript-type">all</span> of the selectors in each
 * <span class="enscript-type">image</span>, <span class="enscript-type">and</span> <span class="enscript-type">fix</span> them <span class="enscript-type">all</span> up.
 *
 **********************************************************************/
static void _objc_fixup_selector_refs   (const header_info *	hi)
{
	unsigned int		midx;
	unsigned int		<span class="enscript-type">size</span>;
	OBJC_PROTOCOL_PTR	protos;
	Module			mods;
	unsigned int		index;
#<span class="enscript-keyword">if</span> defined(__MACH__)
	SEL *			messages_refs;
#endif // __MACH__
	
	mods = (Module) ((unsigned long) hi-&gt;mod_ptr + hi-&gt;image_slide);

	<span class="enscript-keyword">if</span> ( rocketLaunchingDebug )
	{
		printf (&quot;uniquing selectors <span class="enscript-keyword">for</span> <span class="enscript-comment">%s\n&quot;, libraryNameForMachHeader(hi-&gt;mhdr));
</span>		printf (&quot;   uniquing message_refs\n&quot;);
	}
	
#<span class="enscript-keyword">if</span> defined(__MACH__)
	// Fix up message refs
	messages_refs = (SEL *) _getObjcMessageRefs ((headerType *) hi-&gt;mhdr, &amp;<span class="enscript-type">size</span>);
	<span class="enscript-keyword">if</span> (messages_refs)
	{
		messages_refs = (SEL *) ((unsigned long) messages_refs + hi-&gt;image_slide);
		map_selrefs (messages_refs, <span class="enscript-type">size</span>);
	}
#endif // __MACH__

        
#<span class="enscript-keyword">if</span> !defined(__MACH__)
	// This is redundant with the fixup done in _objc_fixup_protocol_objects_for_image()
	// in a little <span class="enscript-keyword">while</span>, at least on MACH.

	// Fix up protocols
	protos = (OBJC_PROTOCOL_PTR) _getObjcProtocols ((headerType *) hi-&gt;mhdr, &amp;<span class="enscript-type">size</span>);
	<span class="enscript-keyword">if</span> (protos)
	{
		protos = (OBJC_PROTOCOL_PTR)((unsigned long)protos + hi-&gt;image_slide);
		
		<span class="enscript-keyword">for</span> (index = 0; index &lt; <span class="enscript-type">size</span>; index += 1)
		{
			// Fix up instance method names
			<span class="enscript-keyword">if</span> (protos<span class="enscript-type">[</span>index<span class="enscript-type">]</span> OBJC_PROTOCOL_DEREF instance_methods)
				map_method_descs (protos<span class="enscript-type">[</span>index<span class="enscript-type">]</span> OBJC_PROTOCOL_DEREF instance_methods);
			
			// Fix up <span class="enscript-type">class</span> method names
			<span class="enscript-keyword">if</span> (protos<span class="enscript-type">[</span>index<span class="enscript-type">]</span> OBJC_PROTOCOL_DEREF class_methods)
				map_method_descs (protos<span class="enscript-type">[</span>index<span class="enscript-type">]</span> OBJC_PROTOCOL_DEREF class_methods);
		}
	}
#endif
}


/***********************************************************************
 * _objc_call_loads_for_image.
 **********************************************************************/
static void _objc_call_loads_for_image (header_info * header)
{
	struct objc_class *			cls;
	struct objc_class * *		pClass;
	Category *			pCategory;
	IMP							load_method;
	unsigned int				nModules;
	unsigned int				nClasses;
	unsigned int				nCategories;
	struct objc_symtab *		symtab;
	struct objc_module *		module;
	
	// Major loop - process <span class="enscript-type">all</span> modules named in header
	module = (struct objc_module *) ((unsigned long) header-&gt;mod_ptr + header-&gt;image_slide);
	<span class="enscript-keyword">for</span> (nModules = header-&gt;mod_count; nModules; nModules -= 1, module += 1)
	{
		symtab = module-&gt;symtab;
		<span class="enscript-keyword">if</span> (symtab == NULL)
			continue;
		
		// Minor loop - call the +<span class="enscript-type">load</span> from each <span class="enscript-type">class</span> in the given module
		<span class="enscript-keyword">for</span> (nClasses = symtab-&gt;cls_def_cnt, pClass = (Class *) symtab-&gt;defs;
		     nClasses;
		     nClasses -= 1, pClass += 1)
		{
			struct objc_method_list **mlistp;
			cls = (struct objc_class *)*pClass;
			mlistp = get_base_method_list(cls-&gt;<span class="enscript-type">isa</span>);
			<span class="enscript-keyword">if</span> (cls-&gt;<span class="enscript-type">isa</span>-&gt;methodLists &amp;&amp; mlistp)
			{
				// Look up the method manually (vs messaging the <span class="enscript-type">class</span>) to bypass
				// +initialize <span class="enscript-type">and</span> cache <span class="enscript-type">fill</span> on <span class="enscript-type">class</span> that is <span class="enscript-type">not</span> even loaded yet
				load_method = class_lookupNamedMethodInMethodList (*mlistp, &quot;<span class="enscript-type">load</span>&quot;);
				<span class="enscript-keyword">if</span> (load_method)
					(*load_method) ((id) cls, @selector(<span class="enscript-type">load</span>));
			}
		}
		
		// Minor loop - call the +<span class="enscript-type">load</span> from augmented <span class="enscript-type">class</span> of
		// each category in the given module
		<span class="enscript-keyword">for</span> (nCategories = symtab-&gt;cat_def_cnt,
			pCategory = (Category *) &amp;symtab-&gt;defs<span class="enscript-type">[</span>symtab-&gt;cls_def_cnt<span class="enscript-type">]</span>;
		     nCategories;
		     nCategories -= 1, pCategory += 1)
		{
			struct objc_method_list *	methods;
			
			cls = objc_getClass ((*pCategory)-&gt;class_name);
			methods = (*pCategory)-&gt;class_methods;
			<span class="enscript-keyword">if</span> (methods)
			{
				load_method = class_lookupNamedMethodInMethodList (methods, &quot;<span class="enscript-type">load</span>&quot;);
				<span class="enscript-keyword">if</span> (load_method)
					(*load_method) ((id) cls, @selector(<span class="enscript-type">load</span>));
			}
		}
	}
}

/***********************************************************************
 * objc_setMultithreaded.
 **********************************************************************/
void objc_setMultithreaded (BOOL flag)
{
	<span class="enscript-keyword">if</span> (flag == YES)
		_objc_multithread_mask = 0;
	<span class="enscript-keyword">else</span>
		_objc_multithread_mask = (-1);
}

/* Library initializer called by dyld. */
void __initialize_objc(void) {
	int hidx;

#<span class="enscript-keyword">if</span> defined(NeXT_PDO)
	const headerType * const *	headers;

        <span class="enscript-keyword">if</span> ( rocketLaunchingDebug == -1 ) {
	    <span class="enscript-keyword">if</span> ( getenv(&quot;OBJC_UNIQUE_DEBUG&quot;) ) rocketLaunchingDebug = 1;
            <span class="enscript-keyword">else</span> rocketLaunchingDebug = 0;
        }

	// Get architecture dependent module headers
	headers = (const headerType * const *) _getObjcHeaders ();
	<span class="enscript-keyword">if</span> (headers)
	{
		// Create vector from these headers
		header_vector = _objc_headerVector (headers);
		<span class="enscript-keyword">if</span> (header_vector) 
		{
			// Load classes from <span class="enscript-type">all</span> images in the vector
			<span class="enscript-keyword">for</span> (hidx = 0; hidx &lt; header_count; hidx += 1)
				(void) _objc_get_classes_from_image (class_hash, &amp;header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>);
		}
	}
#endif
#<span class="enscript-keyword">if</span> defined(__MACH__)
	static int _done = 0;
	extern void __CFInitialize(void);

	/* Protect against multiple invocations, as <span class="enscript-type">all</span> library
	 * initializers should. */
	<span class="enscript-keyword">if</span> (0 != _done) <span class="enscript-keyword">return</span>;
	_done = 1;

	ptrace(0xb000, 0, 0, 0);

	// make sure CF is initialized before we go further;
	// someday this can be removed, as it<span class="enscript-keyword">'</span>ll probably be automatic
	__CFInitialize();

	// Create the <span class="enscript-type">class</span> lookup table
	_objc_init_class_hash ();
	
//	ptrace(0xb001, 0, 0, 0);

	// Get our configuration
        <span class="enscript-keyword">if</span> ( rocketLaunchingDebug == -1 ) {
            <span class="enscript-keyword">if</span> ( getenv(&quot;OBJC_UNIQUE_DEBUG&quot;) ) rocketLaunchingDebug = 1;
            <span class="enscript-keyword">else</span> rocketLaunchingDebug = 0;
        }

//	ptrace(0xb003, 0, 0, 0);

	map_selectors_pended = 1;

// XXXXX BEFORE HERE *NO* PAGES ARE STOMPED ON

	// Register our <span class="enscript-type">image</span> mapping routine with dyld so it
	// gets invoked when an <span class="enscript-type">image</span> is added.  This also invokes
	// the callback right <span class="enscript-type">now</span> on <span class="enscript-type">any</span> images already present.
	_dyld_register_func_for_add_image (&amp;_objc_map_image_callback);
	
// XXXXX BEFORE HERE *ALL* PAGES ARE STOMPED ON

	map_selectors_pended  = 0;
	
//	ptrace(0xb005, 0, 0, 0);
		
	// Register module link callback with dyld
	_dyld_register_func_for_link_module (&amp;_objc_link_module_callback);

	// Register callback with dyld
	_dyld_register_func_for_unlink_module (&amp;_objc_unlink_module_callback);
#endif // MACH

//	ptrace(0xb006, header_count, 0, 0);

	// Install relations on classes that were found
	<span class="enscript-keyword">for</span> (hidx = 0; hidx &lt; header_count; hidx += 1)
	{
		int			nModules;
		int			index;
		struct objc_module *	module;
		struct objc_class *	cls;
		
		module = (struct objc_module *) ((unsigned long) header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.mod_ptr + header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.image_slide);
		<span class="enscript-keyword">for</span> (nModules = header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.mod_count; nModules; nModules -= 1)
		{
			<span class="enscript-keyword">for</span> (index = 0; index &lt; module-&gt;symtab-&gt;cls_def_cnt; index += 1)
			{
				cls = (struct objc_class *) module-&gt;symtab-&gt;defs<span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
				_class_install_relationships (cls, module-&gt;<span class="enscript-type">version</span>);
			}

			module += 1;
		}

//		ptrace(0xb007, hidx, header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.mod_count, 0);
		
	}
	
//	ptrace(0xb008, header_count, 0, 0);
		
	<span class="enscript-keyword">for</span> (hidx = 0; hidx &lt; header_count; hidx += 1)
	{
#<span class="enscript-keyword">if</span> !defined(__MACH__)
		(void)_objc_add_categories_from_image (&amp;header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>);
		(void) _objc_fixup_selector_refs (&amp;header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>);
#endif
		// Initialize the <span class="enscript-type">isa</span> pointers of <span class="enscript-type">all</span> NXConstantString objects
		(void)_objc_fixup_string_objects_for_image (&amp;header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>);

		// Convert <span class="enscript-type">class</span> refs from name pointers to ids
		(void)_objc_map_class_refs_for_image (&amp;header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>);
	}

//	ptrace(0xb00a, 0, 0, 0);
		
	// For each <span class="enscript-type">image</span> selectorize the method names <span class="enscript-type">and</span> +_fixup each of
	// protocols in the <span class="enscript-type">image</span>
	<span class="enscript-keyword">for</span> (hidx = 0; hidx &lt; header_count; hidx += 1)
		_objc_fixup_protocol_objects_for_image (&amp;header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>);
	
#<span class="enscript-keyword">if</span> defined(WIN32) || defined(__svr4__)
	CMH = (objcModHeader *) 0;
#endif

	ptrace(0xb00f, 0, 0, 0);	// <span class="enscript-keyword">end</span> of ObjC init
}

void _objcInit(void) {
	static int _done = 0;
	int hidx;
        /* Protect against multiple invocations, as <span class="enscript-type">all</span> library
         * initializers should. */
        <span class="enscript-keyword">if</span> (0 != _done) <span class="enscript-keyword">return</span>;
        _done = 1;
	ptrace(0xb010, 0, 0, 0);	// marks call to _objcInit
	__initialize_objc();
	/* We delay this until here, because dyld cannot detect <span class="enscript-type">and</span>
	 * properly order calls to ObjC initializers amongst the
	 * calls to module <span class="enscript-type">and</span> library initializers. */
	<span class="enscript-keyword">for</span> (hidx = 0; hidx &lt; header_count; hidx += 1)
		_objc_call_loads_for_image (&amp;header_vector<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>);
	ptrace(0xb01f, 0, 0, 0);	// marks call to _objcInit
}

#<span class="enscript-keyword">if</span> defined(__MACH__)
/***********************************************************************
 * _objc_map_image.
 **********************************************************************/
static void	_objc_map_image(headerType *	mh,
						unsigned long	vmaddr_slide)
{
        static int dumpClasses = -1;
	header_info *					hInfo;
	const struct segment_command *	objcSeg;
	unsigned int					<span class="enscript-type">size</span>;
	
        <span class="enscript-keyword">if</span> ( dumpClasses == -1 ) {
            <span class="enscript-keyword">if</span> ( getenv(&quot;OBJC_DUMP_CLASSES&quot;) ) dumpClasses = 1;
            <span class="enscript-keyword">else</span> dumpClasses = 0;
        }

	ptrace(0xb100, 0, 0, 0);

	// Add this header to the header_vector
	_objc_addHeader (mh, vmaddr_slide);
	
//	ptrace(0xb101, 0, 0, 0);

	// Touch up the vector entry we just added (yuck)
	hInfo = &amp;(header_vector<span class="enscript-type">[</span>header_count-1<span class="enscript-type">]</span>);
	hInfo-&gt;mod_ptr	   = (Module) _getObjcModules ((headerType *) hInfo-&gt;mhdr, &amp;<span class="enscript-type">size</span>);
	hInfo-&gt;mod_count   = <span class="enscript-type">size</span>;
	objcSeg = (struct segment_command *) _getObjcHeaderData ((headerType *) mh, &amp;<span class="enscript-type">size</span>);
	<span class="enscript-keyword">if</span> (objcSeg)
		hInfo-&gt;objcSize = objcSeg-&gt;filesize;
	<span class="enscript-keyword">else</span>
		hInfo-&gt;objcSize = 0;
	
//	ptrace(0xb102, 0, 0, 0);

	// Register <span class="enscript-type">any</span> categories <span class="enscript-type">and</span>/<span class="enscript-type">or</span> classes <span class="enscript-type">and</span>/<span class="enscript-type">or</span> selectors this <span class="enscript-type">image</span> contains
	_objc_add_categories_from_image (hInfo);

//	ptrace(0xb103, 0, 0, 0);

	class_hash = _objc_get_classes_from_image (class_hash, hInfo);

//	ptrace(0xb104, 0, 0, 0);

	_objc_fixup_selector_refs (hInfo);
	
//	ptrace(0xb105, 0, 0, 0);

	// Log <span class="enscript-type">all</span> known <span class="enscript-type">class</span> names, <span class="enscript-keyword">if</span> asked
	<span class="enscript-keyword">if</span> ( dumpClasses )
	{
		printf (&quot;classes<span class="enscript-keyword">...</span>\n&quot;);
		objc_dump_class_hash ();
	}
	
	<span class="enscript-keyword">if</span> (!map_selectors_pended)
	{
		int			nModules;
		int			index;
		struct objc_module *	module;
		
		// Major loop - process each module
		module = (struct objc_module *) ((unsigned long) hInfo-&gt;mod_ptr + hInfo-&gt;image_slide);

//		ptrace(0xb106, hInfo-&gt;mod_count, 0, 0);

		<span class="enscript-keyword">for</span> (nModules = hInfo-&gt;mod_count; nModules; nModules -= 1)
		{
			// Minor loop - process each <span class="enscript-type">class</span> in a given module
			<span class="enscript-keyword">for</span> (index = 0; index &lt; module-&gt;symtab-&gt;cls_def_cnt; index += 1)
			{
				struct objc_class * cls;
				
				// Locate the <span class="enscript-type">class</span> description
				cls = (struct objc_class *) module-&gt;symtab-&gt;defs<span class="enscript-type">[</span>index<span class="enscript-type">]</span>;
				
				// If there is no superclass <span class="enscript-type">or</span> the superclass can be found,
				// install this <span class="enscript-type">class</span>, <span class="enscript-type">and</span> invoke the expected callback
				<span class="enscript-keyword">if</span> (!((struct objc_class *)cls)-&gt;super_class || objc_lookUpClass ((<span class="enscript-type">char</span> *) ((struct objc_class *)cls)-&gt;super_class))
				{
					_class_install_relationships (cls, module-&gt;<span class="enscript-type">version</span>);
					<span class="enscript-keyword">if</span> (callbackFunction)
						(*callbackFunction) (cls, 0);
				}
				
				// Super <span class="enscript-type">class</span> can <span class="enscript-type">not</span> be found yet, arrange <span class="enscript-keyword">for</span> this <span class="enscript-type">class</span> to
				// be filled in later
				<span class="enscript-keyword">else</span>
				{
					objc_pendClassInstallation (cls, module-&gt;<span class="enscript-type">version</span>);
					((struct objc_class *)cls)-&gt;super_class      = _objc_getNonexistentClass ();
					((struct objc_class *)cls)-&gt;<span class="enscript-type">isa</span>-&gt;super_class = _objc_getNonexistentClass ();
				}
			}

			// Move on
			module += 1;
		}
		
//		ptrace(0xb108, 0, 0, 0);

		// Initialize the <span class="enscript-type">isa</span> pointers of <span class="enscript-type">all</span> NXConstantString objects
		_objc_fixup_string_objects_for_image (hInfo);

//		ptrace(0xb109, 0, 0, 0);

		// Convert <span class="enscript-type">class</span> refs from name pointers to ids
		_objc_map_class_refs_for_image (hInfo);

//		ptrace(0xb10a, 0, 0, 0);

		// Selectorize the method names <span class="enscript-type">and</span> +_fixup each of
		// protocols in the <span class="enscript-type">image</span>
		_objc_fixup_protocol_objects_for_image (hInfo);

//		ptrace(0xb10b, 0, 0, 0);

		// Call +<span class="enscript-type">load</span> on <span class="enscript-type">all</span> classes <span class="enscript-type">and</span> categorized classes
		_objc_call_loads_for_image (hInfo);

//		ptrace(0xb10c, 0, 0, 0);
	}
	
	ptrace(0xb10f, 0, 0, 0);
}

static volatile int handling_in_progress = 0;
static volatile int pended_callbacks_count = 0;
static volatile struct {
	headerType *    mh;
	unsigned long   vmaddr_slide;
} pended_callbacks<span class="enscript-type">[</span>250<span class="enscript-type">]</span> = {{0, 0}};

static void	_objc_map_image_callback       (headerType *	mh,
						unsigned long	vmaddr_slide)
{
	pended_callbacks<span class="enscript-type">[</span>pended_callbacks_count<span class="enscript-type">]</span>.mh = mh;
	pended_callbacks<span class="enscript-type">[</span>pended_callbacks_count<span class="enscript-type">]</span>.vmaddr_slide = vmaddr_slide;
	pended_callbacks_count++;
	<span class="enscript-keyword">if</span> (0 != handling_in_progress) <span class="enscript-keyword">return</span>;
	handling_in_progress = 1;
	<span class="enscript-keyword">while</span> (0 &lt; pended_callbacks_count) {
		pended_callbacks_count--;
		_objc_map_image(pended_callbacks<span class="enscript-type">[</span>pended_callbacks_count<span class="enscript-type">]</span>.mh, pended_callbacks<span class="enscript-type">[</span>pended_callbacks_count<span class="enscript-type">]</span>.vmaddr_slide);
	}
	handling_in_progress = 0;
}

#endif // __MACH__

#<span class="enscript-keyword">if</span> defined(__MACH__)
/***********************************************************************
 * _objc_link_module_callback.  Callback installed with
 * _dyld_register_func_for_link_module.
 *
 * NOTE: Why does this <span class="enscript-type">exist</span>?  The old comment said &quot;This will install
 * <span class="enscript-type">class</span> relations <span class="enscript-keyword">for</span> the executable <span class="enscript-type">and</span> dylibs.&quot;  Hmm.
 **********************************************************************/
static void	_objc_link_module_callback     (NSModule	<span class="enscript-type">mod</span>)
{
}

/***********************************************************************
 * _objc_unlink_module_callback.  Callback installed with
 * _dyld_register_func_for_unlink_module.
 **********************************************************************/
static void	_objc_unlink_module_callback   (NSModule	<span class="enscript-type">mod</span>)
{
	_objc_fatal (&quot;unlinking is <span class="enscript-type">not</span> supported in this <span class="enscript-type">version</span> of Objective C\n&quot;);
}
#endif // __MACH__

#<span class="enscript-keyword">if</span> defined(WIN32)
#import &lt;stdlib.h&gt;
/***********************************************************************
 * NSRootDirectory.  Returns the value of the root directory that the
 * product was installed to.
 **********************************************************************/
const <span class="enscript-type">char</span> *	NSRootDirectory	       (void)
{
	static <span class="enscript-type">char</span> *root = (<span class="enscript-type">char</span> *)0;

        <span class="enscript-keyword">if</span> ( ! root ) {
            <span class="enscript-type">char</span> *p = getenv(&quot;NEXT_ROOT&quot;);
            <span class="enscript-keyword">if</span> ( p ) {
                root = malloc_zone_malloc(malloc_default_zone(), strlen(p)+1);
                (void)strcpy(root, p);
            }
            <span class="enscript-keyword">else</span> root = &quot;&quot;;
        }
	<span class="enscript-keyword">return</span> (const <span class="enscript-type">char</span> *)root;
}
#endif 

/***********************************************************************
 * objc_setNilObjectMsgHandler.
 **********************************************************************/
void  objc_setNilObjectMsgHandler   (NilObjectMsgCallback  nilObjMsgCallback)
{
	_objc_msgNil = nilObjMsgCallback;
}

/***********************************************************************
 * objc_getNilObjectMsgHandler.
 **********************************************************************/
NilObjectMsgCallback  objc_getNilObjectMsgHandler   (void)
{
	<span class="enscript-keyword">return</span> _objc_msgNil;
}

#<span class="enscript-keyword">if</span> defined(NeXT_PDO)
// so we have a symbol <span class="enscript-keyword">for</span> libgcc2.c when running PDO
arith_t		_objcInit_addr = (arith_t) _objcInit;
#endif

</pre>
<hr />
</body></html>