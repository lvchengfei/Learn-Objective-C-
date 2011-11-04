<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>hashtable2.m</title>
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
<h1 style="margin:8px;" id="f1">hashtable2.m&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
	hashtable2.m
  	Copyright 1989-1996 NeXT Software, Inc.
	Created by Bertrand Serlet, Feb 89
 */

#<span class="enscript-keyword">if</span> defined(NeXT_PDO)
#import &lt;pdo.h&gt;
#endif

#import &lt;objc/hashtable2.h&gt;
#import &quot;objc-private.h&quot;

/* Is this in the right spot ? &lt;jf&gt; */
#<span class="enscript-keyword">if</span> defined(__osf__)
    #include &lt;stdarg.h&gt;
#endif

    #import &lt;mach/mach.h&gt;
    #import &lt;pthread.h&gt;

/* In order to improve efficiency, buckets contain a pointer to an array <span class="enscript-type">or</span> directly the data when the array <span class="enscript-type">size</span> is 1 */
typedef <span class="enscript-type">union</span> {
    const void	*one;
    const void	**many;
    } oneOrMany;
    /* an optimization consists of storing directly data when count = 1 */
    
typedef struct	{
    unsigned 	count; 
    oneOrMany	elements;
    } HashBucket;
    /* private data structure; may change */
    
/*************************************************************************
 *
 *	Macros <span class="enscript-type">and</span> utilities
 *	
 *************************************************************************/

static unsigned <span class="enscript-type">log2</span> (unsigned x) { <span class="enscript-keyword">return</span> (x&lt;2) ? 0 : <span class="enscript-type">log2</span> (x&gt;&gt;1)+1; };

static unsigned exp2m1 (unsigned x) { <span class="enscript-keyword">return</span> (1 &lt;&lt; x) - 1; };

#define	PTRSIZE		sizeof(void *)

#define	ALLOCTABLE(z)	((NXHashTable *) malloc_zone_malloc (z,sizeof (NXHashTable)))
#define	ALLOCBUCKETS(z,nb)((HashBucket *) malloc_zone_calloc (z, nb, sizeof (HashBucket)))
#define	ALLOCPAIRS(z,nb) ((const void **) malloc_zone_calloc (z, nb, sizeof (void *)))

/* iff necessary this modulo can be optimized since the nbBuckets is of the form 2**n-1 */
#define	BUCKETOF(table, data) (((HashBucket *)table-&gt;buckets)+((*table-&gt;prototype-&gt;hash)(table-&gt;info, data) <span class="enscript-comment">% table-&gt;nbBuckets))
</span>
#define ISEQUAL(table, data1, data2) ((data1 == data2) || (*table-&gt;prototype-&gt;isEqual)(table-&gt;info, data1, data2))
	/* beware of <span class="enscript-type">double</span> evaluation */
	
/*************************************************************************
 *
 *	Global data <span class="enscript-type">and</span> bootstrap
 *	
 *************************************************************************/
 
static int isEqualPrototype (const void *info, const void *data1, const void *data2) {
    NXHashTablePrototype	*proto1 = (NXHashTablePrototype *) data1;
    NXHashTablePrototype	*proto2 = (NXHashTablePrototype *) data2;
    
    <span class="enscript-keyword">return</span> (proto1-&gt;hash == proto2-&gt;hash) &amp;&amp; (proto1-&gt;isEqual == proto2-&gt;isEqual) &amp;&amp; (proto1-&gt;free == proto2-&gt;free) &amp;&amp; (proto1-&gt;style == proto2-&gt;style);
    };
    
static uarith_t hashPrototype (const void *info, const void *data) {
    NXHashTablePrototype	*proto = (NXHashTablePrototype *) data;
    
    <span class="enscript-keyword">return</span> NXPtrHash(info, proto-&gt;hash) ^ NXPtrHash(info, proto-&gt;isEqual) ^ NXPtrHash(info, proto-&gt;free) ^ (uarith_t) proto-&gt;style;
    };

void NXNoEffectFree (const void *info, void *data) {};

static NXHashTablePrototype protoPrototype = {
    hashPrototype, isEqualPrototype, NXNoEffectFree, 0
    };

static NXHashTable *prototypes = NULL;
	/* table of <span class="enscript-type">all</span> prototypes */

static void bootstrap (void) {
    free(malloc(8));
    prototypes = ALLOCTABLE (malloc_default_zone());
    prototypes-&gt;prototype = &amp;protoPrototype; 
    prototypes-&gt;count = 1;
    prototypes-&gt;nbBuckets = 1; /* has to be 1 so that the right bucket is 0 */
    prototypes-&gt;buckets = ALLOCBUCKETS(malloc_default_zone(),  1);
    prototypes-&gt;info = NULL;
    ((HashBucket *) prototypes-&gt;buckets)<span class="enscript-type">[</span>0<span class="enscript-type">]</span>.count = 1;
    ((HashBucket *) prototypes-&gt;buckets)<span class="enscript-type">[</span>0<span class="enscript-type">]</span>.elements.one = &amp;protoPrototype;
    };

int NXPtrIsEqual (const void *info, const void *data1, const void *data2) {
    <span class="enscript-keyword">return</span> data1 == data2;
    };

/*************************************************************************
 *
 *	On z<span class="enscript-keyword">'</span>y va
 *	
 *************************************************************************/

NXHashTable *NXCreateHashTable (NXHashTablePrototype prototype, unsigned capacity, const void *info) {
    <span class="enscript-keyword">return</span> NXCreateHashTableFromZone(prototype, capacity, info, malloc_default_zone());
}

NXHashTable *NXCreateHashTableFromZone (NXHashTablePrototype prototype, unsigned capacity, const void *info, void *z) {
    NXHashTable			*table;
    NXHashTablePrototype	*proto;
    
    table = ALLOCTABLE(z);
    <span class="enscript-keyword">if</span> (! prototypes) bootstrap ();
    <span class="enscript-keyword">if</span> (! prototype.hash) prototype.hash = NXPtrHash;
    <span class="enscript-keyword">if</span> (! prototype.isEqual) prototype.isEqual = NXPtrIsEqual;
    <span class="enscript-keyword">if</span> (! prototype.free) prototype.free = NXNoEffectFree;
    <span class="enscript-keyword">if</span> (prototype.style) {
	_NXLogError (&quot;*** NXCreateHashTable: invalid style\n&quot;);
	<span class="enscript-keyword">return</span> NULL;
	};
    proto = NXHashGet (prototypes, &amp;prototype); 
    <span class="enscript-keyword">if</span> (! proto) {
	proto
	= (NXHashTablePrototype *) malloc_zone_malloc (malloc_default_zone(),
	                                         sizeof (NXHashTablePrototype));
	bcopy ((const <span class="enscript-type">char</span>*)&amp;prototype, (<span class="enscript-type">char</span>*)proto, sizeof (NXHashTablePrototype));
    	(void) NXHashInsert (prototypes, proto);
	proto = NXHashGet (prototypes, &amp;prototype);
	<span class="enscript-keyword">if</span> (! proto) {
	    _NXLogError (&quot;*** NXCreateHashTable: bug\n&quot;);
	    <span class="enscript-keyword">return</span> NULL;
	    };
	};
    table-&gt;prototype = proto; table-&gt;count = 0; table-&gt;info = info;
    table-&gt;nbBuckets = exp2m1 (<span class="enscript-type">log2</span> (capacity)+1);
    table-&gt;buckets = ALLOCBUCKETS(z, table-&gt;nbBuckets);
    <span class="enscript-keyword">return</span> table;
    }

static void freeBucketPairs (void (*freeProc)(const void *info, void *data), HashBucket bucket, const void *info) {
    unsigned	<span class="enscript-type">j</span> = bucket.count;
    const void	**pairs;
    
    <span class="enscript-keyword">if</span> (<span class="enscript-type">j</span> == 1) {
	(*freeProc) (info, (void *) bucket.elements.one);
	<span class="enscript-keyword">return</span>;
	};
    pairs = bucket.elements.many;
    <span class="enscript-keyword">while</span> (<span class="enscript-type">j</span>--) {
	(*freeProc) (info, (void *) *pairs);
	pairs ++;
	};
    free (bucket.elements.many);
    };
    
static void freeBuckets (NXHashTable *table, int freeObjects) {
    unsigned		<span class="enscript-type">i</span> = table-&gt;nbBuckets;
    HashBucket		*buckets = (HashBucket *) table-&gt;buckets;
    
    <span class="enscript-keyword">while</span> (<span class="enscript-type">i</span>--) {
	<span class="enscript-keyword">if</span> (buckets-&gt;count) {
	    freeBucketPairs ((freeObjects) ? table-&gt;prototype-&gt;free : NXNoEffectFree, *buckets, table-&gt;info);
	    buckets-&gt;count = 0;
	    buckets-&gt;elements.one = NULL;
	    };
	buckets++;
	};
    };
    
void NXFreeHashTable (NXHashTable *table) {
    freeBuckets (table, YES);
    free (table-&gt;buckets);
    free (table);
    };
    
void NXEmptyHashTable (NXHashTable *table) {
    freeBuckets (table, NO);
    table-&gt;count = 0;
    }

void NXResetHashTable (NXHashTable *table) {
    freeBuckets (table, YES);
    table-&gt;count = 0;
}

BOOL NXIsEqualHashTable (NXHashTable *table1, NXHashTable *table2) {
    <span class="enscript-keyword">if</span> (table1 == table2) <span class="enscript-keyword">return</span> YES;
    <span class="enscript-keyword">if</span> (NXCountHashTable (table1) != NXCountHashTable (table2)) <span class="enscript-keyword">return</span> NO;
    <span class="enscript-keyword">else</span> {
	void		*data;
	NXHashState	state = NXInitHashState (table1);
	<span class="enscript-keyword">while</span> (NXNextHashState (table1, &amp;state, &amp;data)) {
	    <span class="enscript-keyword">if</span> (! NXHashMember (table2, data)) <span class="enscript-keyword">return</span> NO;
	}
	<span class="enscript-keyword">return</span> YES;
    }
}

BOOL NXCompareHashTables (NXHashTable *table1, NXHashTable *table2) {
    <span class="enscript-keyword">if</span> (table1 == table2) <span class="enscript-keyword">return</span> YES;
    <span class="enscript-keyword">if</span> (NXCountHashTable (table1) != NXCountHashTable (table2)) <span class="enscript-keyword">return</span> NO;
    <span class="enscript-keyword">else</span> {
	void		*data;
	NXHashState	state = NXInitHashState (table1);
	<span class="enscript-keyword">while</span> (NXNextHashState (table1, &amp;state, &amp;data)) {
	    <span class="enscript-keyword">if</span> (! NXHashMember (table2, data)) <span class="enscript-keyword">return</span> NO;
	}
	<span class="enscript-keyword">return</span> YES;
    }
}

NXHashTable *NXCopyHashTable (NXHashTable *table) {
    NXHashTable		*new;
    NXHashState		state = NXInitHashState (table);
    void		*data;
    void 		*z = malloc_zone_from_ptr(table);
    
    new = ALLOCTABLE(z);
    new-&gt;prototype = table-&gt;prototype; new-&gt;count = 0;
    new-&gt;info = table-&gt;info;
    new-&gt;nbBuckets = table-&gt;nbBuckets;
    new-&gt;buckets = ALLOCBUCKETS(z, new-&gt;nbBuckets);
    <span class="enscript-keyword">while</span> (NXNextHashState (table, &amp;state, &amp;data))
	(void) NXHashInsert (new, data);
    <span class="enscript-keyword">return</span> new;
    }

unsigned NXCountHashTable (NXHashTable *table) {
    <span class="enscript-keyword">return</span> table-&gt;count;
    }

int NXHashMember (NXHashTable *table, const void *data) {
    HashBucket	*bucket = BUCKETOF(table, data);
    unsigned	<span class="enscript-type">j</span> = bucket-&gt;count;
    const void	**pairs;
    
    <span class="enscript-keyword">if</span> (! <span class="enscript-type">j</span>) <span class="enscript-keyword">return</span> 0;
    <span class="enscript-keyword">if</span> (<span class="enscript-type">j</span> == 1) {
    	<span class="enscript-keyword">return</span> ISEQUAL(table, data, bucket-&gt;elements.one);
	};
    pairs = bucket-&gt;elements.many;
    <span class="enscript-keyword">while</span> (<span class="enscript-type">j</span>--) {
	/* we don<span class="enscript-keyword">'</span>t cache isEqual because lists are short */
    	<span class="enscript-keyword">if</span> (ISEQUAL(table, data, *pairs)) <span class="enscript-keyword">return</span> 1; 
	pairs ++;
	};
    <span class="enscript-keyword">return</span> 0;
    }

void *NXHashGet (NXHashTable *table, const void *data) {
    HashBucket	*bucket = BUCKETOF(table, data);
    unsigned	<span class="enscript-type">j</span> = bucket-&gt;count;
    const void	**pairs;
    
    <span class="enscript-keyword">if</span> (! <span class="enscript-type">j</span>) <span class="enscript-keyword">return</span> NULL;
    <span class="enscript-keyword">if</span> (<span class="enscript-type">j</span> == 1) {
    	<span class="enscript-keyword">return</span> ISEQUAL(table, data, bucket-&gt;elements.one)
	    ? (void *) bucket-&gt;elements.one : NULL; 
	};
    pairs = bucket-&gt;elements.many;
    <span class="enscript-keyword">while</span> (<span class="enscript-type">j</span>--) {
	/* we don<span class="enscript-keyword">'</span>t cache isEqual because lists are short */
    	<span class="enscript-keyword">if</span> (ISEQUAL(table, data, *pairs)) <span class="enscript-keyword">return</span> (void *) *pairs; 
	pairs ++;
	};
    <span class="enscript-keyword">return</span> NULL;
    }

static void _NXHashRehash (NXHashTable *table) {
    /* Rehash: we create a pseudo table pointing really to the old guys,
    extend self, copy the old pairs, <span class="enscript-type">and</span> free the pseudo table */
    NXHashTable	*old;
    NXHashState	state;
    void	*aux;
    void 	*z = malloc_zone_from_ptr(table);
    
    old = ALLOCTABLE(z);
    old-&gt;prototype = table-&gt;prototype; old-&gt;count = table-&gt;count; 
    old-&gt;nbBuckets = table-&gt;nbBuckets; old-&gt;buckets = table-&gt;buckets;
    table-&gt;nbBuckets += table-&gt;nbBuckets + 1; /* 2 <span class="enscript-type">times</span> + 1 */
    table-&gt;count = 0; table-&gt;buckets = ALLOCBUCKETS(z, table-&gt;nbBuckets);
    state = NXInitHashState (old);
    <span class="enscript-keyword">while</span> (NXNextHashState (old, &amp;state, &amp;aux))
	(void) NXHashInsert (table, aux);
    freeBuckets (old, NO);
    <span class="enscript-keyword">if</span> (old-&gt;count != table-&gt;count)
	_NXLogError(&quot;*** hashtable: count differs after rehashing; probably indicates a broken invariant: there are x <span class="enscript-type">and</span> y such as isEqual(x, y) is TRUE but hash(x) != hash (y)\n&quot;);
    free (old-&gt;buckets); 
    free (old);
    };

void *NXHashInsert (NXHashTable *table, const void *data) {
    HashBucket	*bucket = BUCKETOF(table, data);
    unsigned	<span class="enscript-type">j</span> = bucket-&gt;count;
    const void	**pairs;
    const void	**new;
    void 	*z = malloc_zone_from_ptr(table);
    
    <span class="enscript-keyword">if</span> (! <span class="enscript-type">j</span>) {
	bucket-&gt;count++; bucket-&gt;elements.one = data; 
	table-&gt;count++; 
	<span class="enscript-keyword">return</span> NULL;
	};
    <span class="enscript-keyword">if</span> (<span class="enscript-type">j</span> == 1) {
    	<span class="enscript-keyword">if</span> (ISEQUAL(table, data, bucket-&gt;elements.one)) {
	    const void	*old = bucket-&gt;elements.one;
	    bucket-&gt;elements.one = data;
	    <span class="enscript-keyword">return</span> (void *) old;
	    };
	new = ALLOCPAIRS(z, 2);
	new<span class="enscript-type">[</span>1<span class="enscript-type">]</span> = bucket-&gt;elements.one;
	*new = data;
	bucket-&gt;count++; bucket-&gt;elements.many = new; 
	table-&gt;count++; 
	<span class="enscript-keyword">if</span> (table-&gt;count &gt; table-&gt;nbBuckets) _NXHashRehash (table);
	<span class="enscript-keyword">return</span> NULL;
	};
    pairs = bucket-&gt;elements.many;
    <span class="enscript-keyword">while</span> (<span class="enscript-type">j</span>--) {
	/* we don<span class="enscript-keyword">'</span>t cache isEqual because lists are short */
    	<span class="enscript-keyword">if</span> (ISEQUAL(table, data, *pairs)) {
	    const void	*old = *pairs;
	    *pairs = data;
	    <span class="enscript-keyword">return</span> (void *) old;
	    };
	pairs ++;
	};
    /* we enlarge this bucket; <span class="enscript-type">and</span> put new data in front */
    new = ALLOCPAIRS(z, bucket-&gt;count+1);
    <span class="enscript-keyword">if</span> (bucket-&gt;count) bcopy ((const <span class="enscript-type">char</span>*)bucket-&gt;elements.many, (<span class="enscript-type">char</span>*)(new+1), bucket-&gt;count * PTRSIZE);
    *new = data;
    free (bucket-&gt;elements.many);
    bucket-&gt;count++; bucket-&gt;elements.many = new; 
    table-&gt;count++; 
    <span class="enscript-keyword">if</span> (table-&gt;count &gt; table-&gt;nbBuckets) _NXHashRehash (table);
    <span class="enscript-keyword">return</span> NULL;
    }

void *NXHashInsertIfAbsent (NXHashTable *table, const void *data) {
    HashBucket	*bucket = BUCKETOF(table, data);
    unsigned	<span class="enscript-type">j</span> = bucket-&gt;count;
    const void	**pairs;
    const void	**new;
    void 	*z = malloc_zone_from_ptr(table);
    
    <span class="enscript-keyword">if</span> (! <span class="enscript-type">j</span>) {
	bucket-&gt;count++; bucket-&gt;elements.one = data; 
	table-&gt;count++; 
	<span class="enscript-keyword">return</span> (void *) data;
	};
    <span class="enscript-keyword">if</span> (<span class="enscript-type">j</span> == 1) {
    	<span class="enscript-keyword">if</span> (ISEQUAL(table, data, bucket-&gt;elements.one))
	    <span class="enscript-keyword">return</span> (void *) bucket-&gt;elements.one;
	new = ALLOCPAIRS(z, 2);
	new<span class="enscript-type">[</span>1<span class="enscript-type">]</span> = bucket-&gt;elements.one;
	*new = data;
	bucket-&gt;count++; bucket-&gt;elements.many = new; 
	table-&gt;count++; 
	<span class="enscript-keyword">if</span> (table-&gt;count &gt; table-&gt;nbBuckets) _NXHashRehash (table);
	<span class="enscript-keyword">return</span> (void *) data;
	};
    pairs = bucket-&gt;elements.many;
    <span class="enscript-keyword">while</span> (<span class="enscript-type">j</span>--) {
	/* we don<span class="enscript-keyword">'</span>t cache isEqual because lists are short */
    	<span class="enscript-keyword">if</span> (ISEQUAL(table, data, *pairs))
	    <span class="enscript-keyword">return</span> (void *) *pairs;
	pairs ++;
	};
    /* we enlarge this bucket; <span class="enscript-type">and</span> put new data in front */
    new = ALLOCPAIRS(z, bucket-&gt;count+1);
    <span class="enscript-keyword">if</span> (bucket-&gt;count) bcopy ((const <span class="enscript-type">char</span>*)bucket-&gt;elements.many, (<span class="enscript-type">char</span>*)(new+1), bucket-&gt;count * PTRSIZE);
    *new = data;
    free (bucket-&gt;elements.many);
    bucket-&gt;count++; bucket-&gt;elements.many = new; 
    table-&gt;count++; 
    <span class="enscript-keyword">if</span> (table-&gt;count &gt; table-&gt;nbBuckets) _NXHashRehash (table);
    <span class="enscript-keyword">return</span> (void *) data;
    }

void *NXHashRemove (NXHashTable *table, const void *data) {
    HashBucket	*bucket = BUCKETOF(table, data);
    unsigned	<span class="enscript-type">j</span> = bucket-&gt;count;
    const void	**pairs;
    const void	**new;
    void 	*z = malloc_zone_from_ptr(table);
    
    <span class="enscript-keyword">if</span> (! <span class="enscript-type">j</span>) <span class="enscript-keyword">return</span> NULL;
    <span class="enscript-keyword">if</span> (<span class="enscript-type">j</span> == 1) {
	<span class="enscript-keyword">if</span> (! ISEQUAL(table, data, bucket-&gt;elements.one)) <span class="enscript-keyword">return</span> NULL;
	data = bucket-&gt;elements.one;
	table-&gt;count--; bucket-&gt;count--; bucket-&gt;elements.one = NULL;
	<span class="enscript-keyword">return</span> (void *) data;
	};
    pairs = bucket-&gt;elements.many;
    <span class="enscript-keyword">if</span> (<span class="enscript-type">j</span> == 2) {
    	<span class="enscript-keyword">if</span> (ISEQUAL(table, data, pairs<span class="enscript-type">[</span>0<span class="enscript-type">]</span>)) {
	    bucket-&gt;elements.one = pairs<span class="enscript-type">[</span>1<span class="enscript-type">]</span>; data = pairs<span class="enscript-type">[</span>0<span class="enscript-type">]</span>;
	    }
	<span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> (ISEQUAL(table, data, pairs<span class="enscript-type">[</span>1<span class="enscript-type">]</span>)) {
	    bucket-&gt;elements.one = pairs<span class="enscript-type">[</span>0<span class="enscript-type">]</span>; data = pairs<span class="enscript-type">[</span>1<span class="enscript-type">]</span>;
	    }
	<span class="enscript-keyword">else</span> <span class="enscript-keyword">return</span> NULL;
	free (pairs);
	table-&gt;count--; bucket-&gt;count--;
	<span class="enscript-keyword">return</span> (void *) data;
	};
    <span class="enscript-keyword">while</span> (<span class="enscript-type">j</span>--) {
    	<span class="enscript-keyword">if</span> (ISEQUAL(table, data, *pairs)) {
	    data = *pairs;
	    /* we shrink this bucket */
	    new = (bucket-&gt;count-1) 
		? ALLOCPAIRS(z, bucket-&gt;count-1) : NULL;
	    <span class="enscript-keyword">if</span> (bucket-&gt;count-1 != <span class="enscript-type">j</span>)
		    bcopy ((const <span class="enscript-type">char</span>*)bucket-&gt;elements.many, (<span class="enscript-type">char</span>*)new, PTRSIZE*(bucket-&gt;count-<span class="enscript-type">j</span>-1));
	    <span class="enscript-keyword">if</span> (<span class="enscript-type">j</span>)
		    bcopy ((const <span class="enscript-type">char</span>*)(bucket-&gt;elements.many + bucket-&gt;count-<span class="enscript-type">j</span>), (<span class="enscript-type">char</span>*)(new+bucket-&gt;count-<span class="enscript-type">j</span>-1), PTRSIZE*<span class="enscript-type">j</span>);
	    free (bucket-&gt;elements.many);
	    table-&gt;count--; bucket-&gt;count--; bucket-&gt;elements.many = new;
	    <span class="enscript-keyword">return</span> (void *) data;
	    };
	pairs ++;
	};
    <span class="enscript-keyword">return</span> NULL;
    }

NXHashState NXInitHashState (NXHashTable *table) {
    NXHashState	state;
    
    state.<span class="enscript-type">i</span> = table-&gt;nbBuckets;
    state.<span class="enscript-type">j</span> = 0;
    <span class="enscript-keyword">return</span> state;
    };
    
int NXNextHashState (NXHashTable *table, NXHashState *state, void **data) {
    HashBucket		*buckets = (HashBucket *) table-&gt;buckets;
    
    <span class="enscript-keyword">while</span> (state-&gt;<span class="enscript-type">j</span> == 0) {
	<span class="enscript-keyword">if</span> (state-&gt;<span class="enscript-type">i</span> == 0) <span class="enscript-keyword">return</span> NO;
	state-&gt;<span class="enscript-type">i</span>--; state-&gt;<span class="enscript-type">j</span> = buckets<span class="enscript-type">[</span>state-&gt;<span class="enscript-type">i</span><span class="enscript-type">]</span>.count;
	}
    state-&gt;<span class="enscript-type">j</span>--;
    buckets += state-&gt;<span class="enscript-type">i</span>;
    *data = (void *) ((buckets-&gt;count == 1) 
    		? buckets-&gt;elements.one : buckets-&gt;elements.many<span class="enscript-type">[</span>state-&gt;<span class="enscript-type">j</span><span class="enscript-type">]</span>);
    <span class="enscript-keyword">return</span> YES;
    };

/*************************************************************************
 *
 *	Conveniences
 *	
 *************************************************************************/

uarith_t NXPtrHash (const void *info, const void *data) {
    <span class="enscript-keyword">return</span> (((uarith_t) data) &gt;&gt; 16) ^ ((uarith_t) data);
    };
    
uarith_t NXStrHash (const void *info, const void *data) {
    register uarith_t	hash = 0;
    register unsigned <span class="enscript-type">char</span>	*s = (unsigned <span class="enscript-type">char</span> *) data;
    /* unsigned to avoid a <span class="enscript-type">sign</span>-extend */
    /* unroll the loop */
    <span class="enscript-keyword">if</span> (s) <span class="enscript-keyword">for</span> (; ; ) { 
	<span class="enscript-keyword">if</span> (*s == <span class="enscript-string">'\0'</span>) <span class="enscript-keyword">break</span>;
	hash ^= (uarith_t) *s++;
	<span class="enscript-keyword">if</span> (*s == <span class="enscript-string">'\0'</span>) <span class="enscript-keyword">break</span>;
	hash ^= (uarith_t) *s++ &lt;&lt; 8;
	<span class="enscript-keyword">if</span> (*s == <span class="enscript-string">'\0'</span>) <span class="enscript-keyword">break</span>;
	hash ^= (uarith_t) *s++ &lt;&lt; 16;
	<span class="enscript-keyword">if</span> (*s == <span class="enscript-string">'\0'</span>) <span class="enscript-keyword">break</span>;
	hash ^= (uarith_t) *s++ &lt;&lt; 24;
	}
    <span class="enscript-keyword">return</span> hash;
    };
    
int NXStrIsEqual (const void *info, const void *data1, const void *data2) {
    <span class="enscript-keyword">if</span> (data1 == data2) <span class="enscript-keyword">return</span> YES;
    <span class="enscript-keyword">if</span> (! data1) <span class="enscript-keyword">return</span> ! strlen ((<span class="enscript-type">char</span> *) data2);
    <span class="enscript-keyword">if</span> (! data2) <span class="enscript-keyword">return</span> ! strlen ((<span class="enscript-type">char</span> *) data1);
    <span class="enscript-keyword">if</span> (((<span class="enscript-type">char</span> *) data1)<span class="enscript-type">[</span>0<span class="enscript-type">]</span> != ((<span class="enscript-type">char</span> *) data2)<span class="enscript-type">[</span>0<span class="enscript-type">]</span>) <span class="enscript-keyword">return</span> NO;
    <span class="enscript-keyword">return</span> (<span class="enscript-type">strcmp</span> ((<span class="enscript-type">char</span> *) data1, (<span class="enscript-type">char</span> *) data2)) ? NO : YES;
    };
    
void NXReallyFree (const void *info, void *data) {
    free (data);
    };

/* All the following functions are really private, made non-static only <span class="enscript-keyword">for</span> the benefit of shlibs */
static uarith_t hashPtrStructKey (const void *info, const void *data) {
    <span class="enscript-keyword">return</span> NXPtrHash(info, *((void **) data));
    };

static int isEqualPtrStructKey (const void *info, const void *data1, const void *data2) {
    <span class="enscript-keyword">return</span> NXPtrIsEqual (info, *((void **) data1), *((void **) data2));
    };

static uarith_t hashStrStructKey (const void *info, const void *data) {
    <span class="enscript-keyword">return</span> NXStrHash(info, *((<span class="enscript-type">char</span> **) data));
    };

static int isEqualStrStructKey (const void *info, const void *data1, const void *data2) {
    <span class="enscript-keyword">return</span> NXStrIsEqual (info, *((<span class="enscript-type">char</span> **) data1), *((<span class="enscript-type">char</span> **) data2));
    };

const NXHashTablePrototype NXPtrPrototype = {
    NXPtrHash, NXPtrIsEqual, NXNoEffectFree, 0
    };

const NXHashTablePrototype NXStrPrototype = {
    NXStrHash, NXStrIsEqual, NXNoEffectFree, 0
    };

const NXHashTablePrototype NXPtrStructKeyPrototype = {
    hashPtrStructKey, isEqualPtrStructKey, NXReallyFree, 0
    };

const NXHashTablePrototype NXStrStructKeyPrototype = {
    hashStrStructKey, isEqualStrStructKey, NXReallyFree, 0
    };

/*************************************************************************
 *
 *	Unique <span class="enscript-type">strings</span>
 *	
 *************************************************************************/

/* the implementation could be made faster at the expense of memory <span class="enscript-keyword">if</span> the <span class="enscript-type">size</span> of the <span class="enscript-type">strings</span> were kept around */
static NXHashTable *uniqueStrings = NULL;

/* this is based on most apps using a few K of <span class="enscript-type">strings</span>, <span class="enscript-type">and</span> an average string <span class="enscript-type">size</span> of 15 using <span class="enscript-type">sqrt</span>(2*dataAlloced*perChunkOverhead) */
#define CHUNK_SIZE	360

static int accessUniqueString = 0;

static <span class="enscript-type">char</span>		*z = NULL;
static vm_size_t	zSize = 0;
static mutex_t		lock = (mutex_t)0;

static const <span class="enscript-type">char</span> *CopyIntoReadOnly (const <span class="enscript-type">char</span> *str) {
    unsigned int	len = strlen (str) + 1;
    <span class="enscript-type">char</span>	*new;
    
    <span class="enscript-keyword">if</span> (len &gt; CHUNK_SIZE/2) {	/* dont let big <span class="enscript-type">strings</span> waste space */
	new = malloc (len);
	bcopy (str, new, len);
	<span class="enscript-keyword">return</span> new;
    }

    <span class="enscript-keyword">if</span> (! lock) {
    	lock = (mutex_t)mutex_alloc ();
	mutex_init (lock);
	};

    mutex_lock (lock);
    <span class="enscript-keyword">if</span> (zSize &lt; len) {
	zSize = CHUNK_SIZE *((len + CHUNK_SIZE - 1) / CHUNK_SIZE);
	/* <span class="enscript-type">not</span> enough room, we <span class="enscript-type">try</span> to allocate.  If no room left, too bad */
	z = malloc (zSize);
	};
    
    new = z;
    bcopy (str, new, len);
    z += len;
    zSize -= len;
    mutex_unlock (lock);
    <span class="enscript-keyword">return</span> new;
    };
    
NXAtom NXUniqueString (const <span class="enscript-type">char</span> *buffer) {
    const <span class="enscript-type">char</span>	*previous;
    
    <span class="enscript-keyword">if</span> (! buffer) <span class="enscript-keyword">return</span> buffer;
    accessUniqueString++;
    <span class="enscript-keyword">if</span> (! uniqueStrings)
    	uniqueStrings = NXCreateHashTable (NXStrPrototype, 0, NULL);
    previous = (const <span class="enscript-type">char</span> *) NXHashGet (uniqueStrings, buffer);
    <span class="enscript-keyword">if</span> (previous) <span class="enscript-keyword">return</span> previous;
    previous = CopyIntoReadOnly (buffer);
    <span class="enscript-keyword">if</span> (NXHashInsert (uniqueStrings, previous)) {
	_NXLogError (&quot;*** NXUniqueString: invariant broken\n&quot;);
	<span class="enscript-keyword">return</span> NULL;
	};
    <span class="enscript-keyword">return</span> previous;
    };

NXAtom NXUniqueStringNoCopy (const <span class="enscript-type">char</span> *string) {
    accessUniqueString++;
    <span class="enscript-keyword">if</span> (! uniqueStrings)
    	uniqueStrings = NXCreateHashTable (NXStrPrototype, 0, NULL);
    <span class="enscript-keyword">return</span> (const <span class="enscript-type">char</span> *) NXHashInsertIfAbsent (uniqueStrings, string);
    };

#define BUF_SIZE	256

NXAtom NXUniqueStringWithLength (const <span class="enscript-type">char</span> *buffer, int <span class="enscript-type">length</span>) {
    NXAtom	atom;
    <span class="enscript-type">char</span>	*nullTermStr;
    <span class="enscript-type">char</span>	stackBuf<span class="enscript-type">[</span>BUF_SIZE<span class="enscript-type">]</span>;

    <span class="enscript-keyword">if</span> (<span class="enscript-type">length</span>+1 &gt; BUF_SIZE)
	nullTermStr = malloc (<span class="enscript-type">length</span>+1);
    <span class="enscript-keyword">else</span>
	nullTermStr = stackBuf;
    bcopy (buffer, nullTermStr, <span class="enscript-type">length</span>);
    nullTermStr<span class="enscript-type">[</span><span class="enscript-type">length</span><span class="enscript-type">]</span> = <span class="enscript-string">'\0'</span>;
    atom = NXUniqueString (nullTermStr);
    <span class="enscript-keyword">if</span> (<span class="enscript-type">length</span>+1 &gt; BUF_SIZE)
	free (nullTermStr);
    <span class="enscript-keyword">return</span> atom;
    };

<span class="enscript-type">char</span> *NXCopyStringBufferFromZone (const <span class="enscript-type">char</span> *str, void *z) {
    <span class="enscript-keyword">return</span> strcpy ((<span class="enscript-type">char</span> *) malloc_zone_malloc(z, strlen (str) + 1), str);
    };
    
<span class="enscript-type">char</span> *NXCopyStringBuffer (const <span class="enscript-type">char</span> *str) {
    <span class="enscript-keyword">return</span> NXCopyStringBufferFromZone(str, malloc_default_zone());
    };

</pre>
<hr />
</body></html>