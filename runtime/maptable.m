<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>maptable.m</title>
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
<h1 style="margin:8px;" id="f1">maptable.m&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
/*	maptable.m
  	Copyright 1990-1996 NeXT Software, Inc.
	Created by Bertrand Serlet, August 1990
 */

#<span class="enscript-keyword">if</span> defined(WIN32)
    #include &lt;winnt-pdo.h&gt;
#endif

#import &quot;objc-private.h&quot;
#import &quot;maptable.h&quot;

#import &lt;string.h&gt;
#import &lt;stdlib.h&gt;
#import &lt;stdio.h&gt;
#import &lt;objc/Object.h&gt;
#import &lt;objc/hashtable2.h&gt;

#<span class="enscript-keyword">if</span> defined(NeXT_PDO)
    #import &lt;pdo.h&gt;
#endif

/******		Macros <span class="enscript-type">and</span> utilities	****************************/

#<span class="enscript-keyword">if</span> defined(DEBUG)
    #define INLINE	
#<span class="enscript-keyword">else</span>
    #define INLINE <span class="enscript-type">inline</span>
#endif

typedef struct _MapPair {
    const void	*key;
    const void	*value;
} MapPair;

static unsigned <span class="enscript-type">log2</span>(unsigned x) { <span class="enscript-keyword">return</span> (x&lt;2) ? 0 : <span class="enscript-type">log2</span>(x&gt;&gt;1)+1; };

static INLINE unsigned exp2m1(unsigned x) { <span class="enscript-keyword">return</span> (1 &lt;&lt; x) - 1; };

/* iff necessary this modulo can be optimized since the nbBuckets is of the form 2**n-1 */
static INLINE unsigned bucketOf(NXMapTable *table, const void *key) {
    unsigned	hash = (table-&gt;prototype-&gt;hash)(table, key);
    unsigned	xored = (hash &amp; 0xffff) ^ (hash &gt;&gt; 16);
    <span class="enscript-keyword">return</span> ((xored * 65521) + hash) <span class="enscript-comment">% table-&gt;nbBuckets;
</span>}

static INLINE int isEqual(NXMapTable *table, const void *key1, const void *key2) {
    <span class="enscript-keyword">return</span> (key1 == key2) ? 1 : (table-&gt;prototype-&gt;isEqual)(table, key1, key2);
}

static INLINE unsigned nextIndex(NXMapTable *table, unsigned index) {
    <span class="enscript-keyword">return</span> (index+1 &gt;= table-&gt;nbBuckets) ? 0 : index+1;
}

static INLINE void *allocBuckets(void *z, unsigned nb) {
    MapPair	*pairs = malloc_zone_malloc(z, (nb * sizeof(MapPair)));
    MapPair	*pair = pairs;
    <span class="enscript-keyword">while</span> (nb--) { pair-&gt;key = NX_MAPNOTAKEY; pair-&gt;value = NULL; pair++; }
    <span class="enscript-keyword">return</span> pairs;
}

/*****		Global data <span class="enscript-type">and</span> bootstrap	**********************/

static int isEqualPrototype (const void *info, const void *data1, const void *data2) {
    NXHashTablePrototype        *proto1 = (NXHashTablePrototype *) data1;
    NXHashTablePrototype        *proto2 = (NXHashTablePrototype *) data2;

    <span class="enscript-keyword">return</span> (proto1-&gt;hash == proto2-&gt;hash) &amp;&amp; (proto1-&gt;isEqual == proto2-&gt;isEqual) &amp;&amp; (proto1-&gt;free == proto2-&gt;free) &amp;&amp; (proto1-&gt;style == proto2-&gt;style);
    };

static uarith_t hashPrototype (const void *info, const void *data) {
    NXHashTablePrototype        *proto = (NXHashTablePrototype *) data;

    <span class="enscript-keyword">return</span> NXPtrHash(info, proto-&gt;hash) ^ NXPtrHash(info, proto-&gt;isEqual) ^ NXPtrHash(info, proto-&gt;free) ^ (uarith_t) proto-&gt;style;
    };

static NXHashTablePrototype protoPrototype = {
    hashPrototype, isEqualPrototype, NXNoEffectFree, 0
};

static NXHashTable *prototypes = NULL;
	/* table of <span class="enscript-type">all</span> prototypes */

/****		Fundamentals Operations			**************/

NXMapTable *NXCreateMapTableFromZone(NXMapTablePrototype prototype, unsigned capacity, void *z) {
    NXMapTable			*table = malloc_zone_malloc(z, sizeof(NXMapTable));
    NXMapTablePrototype		*proto;
    <span class="enscript-keyword">if</span> (! prototypes) prototypes = NXCreateHashTable(protoPrototype, 0, NULL);
    <span class="enscript-keyword">if</span> (! prototype.hash || ! prototype.isEqual || ! prototype.free || prototype.style) {
	_NXLogError(&quot;*** NXCreateMapTable: invalid creation parameters\n&quot;);
	<span class="enscript-keyword">return</span> NULL;
    }
    proto = NXHashGet(prototypes, &amp;prototype); 
    <span class="enscript-keyword">if</span> (! proto) {
	proto = malloc(sizeof(NXMapTablePrototype));
	*proto = prototype;
    	(void)NXHashInsert(prototypes, proto);
    }
    table-&gt;prototype = proto; table-&gt;count = 0;
    table-&gt;nbBuckets = exp2m1(<span class="enscript-type">log2</span>(capacity)+1);
    table-&gt;buckets = allocBuckets(z, table-&gt;nbBuckets);
    <span class="enscript-keyword">return</span> table;
}

NXMapTable *NXCreateMapTable(NXMapTablePrototype prototype, unsigned capacity) {
    <span class="enscript-keyword">return</span> NXCreateMapTableFromZone(prototype, capacity, malloc_default_zone());
}

void NXFreeMapTable(NXMapTable *table) {
    NXResetMapTable(table);
    free(table-&gt;buckets);
    free(table);
}

void NXResetMapTable(NXMapTable *table) {
    MapPair	*pairs = table-&gt;buckets;
    void	(*freeProc)(struct _NXMapTable *, void *, void *) = table-&gt;prototype-&gt;free;
    unsigned	index = table-&gt;nbBuckets;
    <span class="enscript-keyword">while</span> (index--) {
	<span class="enscript-keyword">if</span> (pairs-&gt;key != NX_MAPNOTAKEY) {
	    freeProc(table, (void *)pairs-&gt;key, (void *)pairs-&gt;value);
	    pairs-&gt;key = NX_MAPNOTAKEY; pairs-&gt;value = NULL;
	}
	pairs++;
    }
    table-&gt;count = 0;
}

BOOL NXCompareMapTables(NXMapTable *table1, NXMapTable *table2) {
    <span class="enscript-keyword">if</span> (table1 == table2) <span class="enscript-keyword">return</span> YES;
    <span class="enscript-keyword">if</span> (table1-&gt;count != table2-&gt;count) <span class="enscript-keyword">return</span> NO;
    <span class="enscript-keyword">else</span> {
	const void *key;
	const void *value;
	NXMapState	state = NXInitMapState(table1);
	<span class="enscript-keyword">while</span> (NXNextMapState(table1, &amp;state, &amp;key, &amp;value)) {
	    <span class="enscript-keyword">if</span> (NXMapMember(table2, key, (void**)&amp;value) == NX_MAPNOTAKEY) <span class="enscript-keyword">return</span> NO;
	}
	<span class="enscript-keyword">return</span> YES;
    }
}

unsigned NXCountMapTable(NXMapTable *table) { <span class="enscript-keyword">return</span> table-&gt;count; }

static int mapSearch = 0;
static int mapSearchHit = 0;
static int mapSearchLoop = 0;

static INLINE void *_NXMapMember(NXMapTable *table, const void *key, void **value) {
    MapPair	*pairs = table-&gt;buckets;
    unsigned	index = bucketOf(table, key);
    MapPair	*pair = pairs + index;
    <span class="enscript-keyword">if</span> (pair-&gt;key == NX_MAPNOTAKEY) <span class="enscript-keyword">return</span> NX_MAPNOTAKEY;
    mapSearch ++;
    <span class="enscript-keyword">if</span> (isEqual(table, pair-&gt;key, key)) {
	*value = (void *)pair-&gt;value;
	mapSearchHit ++;
	<span class="enscript-keyword">return</span> (void *)pair-&gt;key;
    } <span class="enscript-keyword">else</span> {
	unsigned	index2 = index;
	<span class="enscript-keyword">while</span> ((index2 = nextIndex(table, index2)) != index) {
	    mapSearchLoop ++;
	    pair = pairs + index2;
	    <span class="enscript-keyword">if</span> (pair-&gt;key == NX_MAPNOTAKEY) <span class="enscript-keyword">return</span> NX_MAPNOTAKEY;
	    <span class="enscript-keyword">if</span> (isEqual(table, pair-&gt;key, key)) {
	    	*value = (void *)pair-&gt;value;
		<span class="enscript-keyword">return</span> (void *)pair-&gt;key;
	    }
	}
	<span class="enscript-keyword">return</span> NX_MAPNOTAKEY;
    }
}

void *NXMapMember(NXMapTable *table, const void *key, void **value) {
    <span class="enscript-keyword">return</span> _NXMapMember(table, key, value);
}

void *NXMapGet(NXMapTable *table, const void *key) {
    void	*value;
    <span class="enscript-keyword">return</span> (_NXMapMember(table, key, &amp;value) != NX_MAPNOTAKEY) ? value : NULL;
}

static int mapRehash = 0;
static int mapRehashSum = 0;

static void _NXMapRehash(NXMapTable *table) {
    MapPair	*pairs = table-&gt;buckets;
    MapPair	*pair = pairs;
    unsigned	index = table-&gt;nbBuckets;
    unsigned	oldCount = table-&gt;count;
    table-&gt;nbBuckets += table-&gt;nbBuckets + 1; /* 2 <span class="enscript-type">times</span> + 1 */
    table-&gt;count = 0; 
    table-&gt;buckets = allocBuckets(malloc_zone_from_ptr(table), table-&gt;nbBuckets);
    mapRehash ++;
    mapRehashSum += table-&gt;count;
    <span class="enscript-keyword">while</span> (index--) {
	<span class="enscript-keyword">if</span> (pair-&gt;key != NX_MAPNOTAKEY) {
	    (void)NXMapInsert(table, pair-&gt;key, pair-&gt;value);
	}
	pair++;
    }
    <span class="enscript-keyword">if</span> (oldCount != table-&gt;count)
	_NXLogError(&quot;*** maptable: count differs after rehashing; probably indicates a broken invariant: there are x <span class="enscript-type">and</span> y such as isEqual(x, y) is TRUE but hash(x) != hash (y)\n&quot;);
    free(pairs); 
}

static int mapInsert = 0;
static int mapInsertHit = 0;
static int mapInsertLoop = 0;

void *NXMapInsert(NXMapTable *table, const void *key, const void *value) {
    MapPair	*pairs = table-&gt;buckets;
    unsigned	index = bucketOf(table, key);
    MapPair	*pair = pairs + index;
    <span class="enscript-keyword">if</span> (key == NX_MAPNOTAKEY) {
	_NXLogError(&quot;*** NXMapInsert: invalid key: -1\n&quot;);
	<span class="enscript-keyword">return</span> NULL;
    }
    mapInsert ++;
    <span class="enscript-keyword">if</span> (pair-&gt;key == NX_MAPNOTAKEY) {
	mapInsertHit ++;
	pair-&gt;key = key; pair-&gt;value = value;
	table-&gt;count++;
	<span class="enscript-keyword">return</span> NULL;
    }
    <span class="enscript-keyword">if</span> (isEqual(table, pair-&gt;key, key)) {
	const void	*old = pair-&gt;value;
	mapInsertHit ++;
	<span class="enscript-keyword">if</span> (old != value) pair-&gt;value = value;/* avoid writing unless needed! */
	<span class="enscript-keyword">return</span> (void *)old;
    } <span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> (table-&gt;count == table-&gt;nbBuckets) {
	/* no room: rehash <span class="enscript-type">and</span> retry */
	_NXMapRehash(table);
	<span class="enscript-keyword">return</span> NXMapInsert(table, key, value);
    } <span class="enscript-keyword">else</span> {
	unsigned	index2 = index;
	<span class="enscript-keyword">while</span> ((index2 = nextIndex(table, index2)) != index) {
	    mapInsertLoop ++;
	    pair = pairs + index2;
	    <span class="enscript-keyword">if</span> (pair-&gt;key == NX_MAPNOTAKEY) {
    #<span class="enscript-keyword">if</span> INSERT_TAIL
              pair-&gt;key = key; pair-&gt;value = value;
    #<span class="enscript-keyword">else</span>
              MapPair         current = {key, value};
              index2 = index;
              <span class="enscript-keyword">while</span> (current.key != NX_MAPNOTAKEY) {
                  MapPair             temp;
                  pair = pairs + index2;
                  temp = *pair;
                  *pair = current;
                  current = temp;
                  index2 = nextIndex(table, index2);
              }
    #endif
		table-&gt;count++;
		<span class="enscript-keyword">if</span> (table-&gt;count * 4 &gt; table-&gt;nbBuckets * 3) _NXMapRehash(table);
		<span class="enscript-keyword">return</span> NULL;
	    }
	    <span class="enscript-keyword">if</span> (isEqual(table, pair-&gt;key, key)) {
		const void	*old = pair-&gt;value;
		<span class="enscript-keyword">if</span> (old != value) pair-&gt;value = value;/* avoid writing unless needed! */
		<span class="enscript-keyword">return</span> (void *)old;
	    }
	}
	/* no room: can<span class="enscript-keyword">'</span>t happen! */
	_NXLogError(&quot;**** NXMapInsert: bug\n&quot;);
	<span class="enscript-keyword">return</span> NULL;
    }
}

static int mapRemove = 0;

void *NXMapRemove(NXMapTable *table, const void *key) {
    MapPair	*pairs = table-&gt;buckets;
    unsigned	index = bucketOf(table, key);
    MapPair	*pair = pairs + index;
    unsigned	chain = 1; /* number of non-nil pairs in a row */
    int		found = 0;
    const void	*old = NULL;
    <span class="enscript-keyword">if</span> (pair-&gt;key == NX_MAPNOTAKEY) <span class="enscript-keyword">return</span> NULL;
    mapRemove ++;
    /* compute chain */
    {
	unsigned	index2 = index;
	<span class="enscript-keyword">if</span> (isEqual(table, pair-&gt;key, key)) {found ++; old = pair-&gt;value; }
	<span class="enscript-keyword">while</span> ((index2 = nextIndex(table, index2)) != index) {
	    pair = pairs + index2;
	    <span class="enscript-keyword">if</span> (pair-&gt;key == NX_MAPNOTAKEY) <span class="enscript-keyword">break</span>;
	    <span class="enscript-keyword">if</span> (isEqual(table, pair-&gt;key, key)) {found ++; old = pair-&gt;value; }
	    chain++;
	}
    }
    <span class="enscript-keyword">if</span> (! found) <span class="enscript-keyword">return</span> NULL;
    <span class="enscript-keyword">if</span> (found != 1) _NXLogError(&quot;**** NXMapRemove: incorrect table\n&quot;);
    /* remove then reinsert */
    {
	MapPair	buffer<span class="enscript-type">[</span>16<span class="enscript-type">]</span>;
	MapPair	*aux = (chain &gt; 16) ? malloc(sizeof(MapPair)*(chain-1)) : buffer;
	int	auxnb = 0;
	int	nb = chain;
	unsigned	index2 = index;
	<span class="enscript-keyword">while</span> (nb--) {
	    pair = pairs + index2;
	    <span class="enscript-keyword">if</span> (! isEqual(table, pair-&gt;key, key)) aux<span class="enscript-type">[</span>auxnb++<span class="enscript-type">]</span> = *pair;
	    pair-&gt;key = NX_MAPNOTAKEY; pair-&gt;value = NULL;
	    index2 = nextIndex(table, index2);
	}
	table-&gt;count -= chain;
	<span class="enscript-keyword">if</span> (auxnb != chain-1) _NXLogError(&quot;**** NXMapRemove: bug\n&quot;);
	<span class="enscript-keyword">while</span> (auxnb--) NXMapInsert(table, aux<span class="enscript-type">[</span>auxnb<span class="enscript-type">]</span>.key, aux<span class="enscript-type">[</span>auxnb<span class="enscript-type">]</span>.value);
	<span class="enscript-keyword">if</span> (chain &gt; 16) free(aux);
    }
    <span class="enscript-keyword">return</span> (void *)old;
}

NXMapState NXInitMapState(NXMapTable *table) {
    NXMapState	state;
    state.index = table-&gt;nbBuckets;
    <span class="enscript-keyword">return</span> state;
}
    
int NXNextMapState(NXMapTable *table, NXMapState *state, const void **key, const void **value) {
    MapPair	*pairs = table-&gt;buckets;
    <span class="enscript-keyword">while</span> (state-&gt;index--) {
	MapPair	*pair = pairs + state-&gt;index;
	<span class="enscript-keyword">if</span> (pair-&gt;key != NX_MAPNOTAKEY) {
	    *key = pair-&gt;key; *value = pair-&gt;value;
	    <span class="enscript-keyword">return</span> YES;
	}
    }
    <span class="enscript-keyword">return</span> NO;
}

/****		Conveniences		*************************************/

static unsigned _mapPtrHash(NXMapTable *table, const void *key) {
    <span class="enscript-keyword">return</span> (((uarith_t) key) &gt;&gt; ARITH_SHIFT) ^ ((uarith_t) key);
}
    
static unsigned _mapStrHash(NXMapTable *table, const void *key) {
    unsigned		hash = 0;
    unsigned <span class="enscript-type">char</span>	*s = (unsigned <span class="enscript-type">char</span> *)key;
    /* unsigned to avoid a <span class="enscript-type">sign</span>-extend */
    /* unroll the loop */
    <span class="enscript-keyword">if</span> (s) <span class="enscript-keyword">for</span> (; ; ) { 
	<span class="enscript-keyword">if</span> (*s == <span class="enscript-string">'\0'</span>) <span class="enscript-keyword">break</span>;
	hash ^= *s++;
	<span class="enscript-keyword">if</span> (*s == <span class="enscript-string">'\0'</span>) <span class="enscript-keyword">break</span>;
	hash ^= *s++ &lt;&lt; 8;
	<span class="enscript-keyword">if</span> (*s == <span class="enscript-string">'\0'</span>) <span class="enscript-keyword">break</span>;
	hash ^= *s++ &lt;&lt; 16;
	<span class="enscript-keyword">if</span> (*s == <span class="enscript-string">'\0'</span>) <span class="enscript-keyword">break</span>;
	hash ^= *s++ &lt;&lt; 24;
    }
    <span class="enscript-keyword">return</span> hash;
}
    
static unsigned _mapObjectHash(NXMapTable *table, const void *key) {
    <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>(id)key hash<span class="enscript-type">]</span>;
}
    
static int _mapPtrIsEqual(NXMapTable *table, const void *key1, const void *key2) {
    <span class="enscript-keyword">return</span> key1 == key2;
}

static int _mapStrIsEqual(NXMapTable *table, const void *key1, const void *key2) {
    <span class="enscript-keyword">if</span> (key1 == key2) <span class="enscript-keyword">return</span> YES;
    <span class="enscript-keyword">if</span> (! key1) <span class="enscript-keyword">return</span> ! strlen ((<span class="enscript-type">char</span> *) key2);
    <span class="enscript-keyword">if</span> (! key2) <span class="enscript-keyword">return</span> ! strlen ((<span class="enscript-type">char</span> *) key1);
    <span class="enscript-keyword">if</span> (((<span class="enscript-type">char</span> *) key1)<span class="enscript-type">[</span>0<span class="enscript-type">]</span> != ((<span class="enscript-type">char</span> *) key2)<span class="enscript-type">[</span>0<span class="enscript-type">]</span>) <span class="enscript-keyword">return</span> NO;
    <span class="enscript-keyword">return</span> (<span class="enscript-type">strcmp</span>((<span class="enscript-type">char</span> *) key1, (<span class="enscript-type">char</span> *) key2)) ? NO : YES;
}
    
static int _mapObjectIsEqual(NXMapTable *table, const void *key1, const void *key2) {
    <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>(id)key1 isEqual:(id)key2<span class="enscript-type">]</span>;
}
    
static void _mapNoFree(NXMapTable *table, void *key, void *value) {}

static void _mapObjectFree(NXMapTable *table, void *key, void *value) {
    <span class="enscript-type">[</span>(id)key free<span class="enscript-type">]</span>;
}

const NXMapTablePrototype NXPtrValueMapPrototype = {
    _mapPtrHash, _mapPtrIsEqual, _mapNoFree, 0
};

const NXMapTablePrototype NXStrValueMapPrototype = {
    _mapStrHash, _mapStrIsEqual, _mapNoFree, 0
};

const NXMapTablePrototype NXObjectMapPrototype = {
    _mapObjectHash, _mapObjectIsEqual, _mapObjectFree, 0
};

</pre>
<hr />
</body></html>