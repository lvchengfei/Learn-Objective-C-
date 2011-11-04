<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>maptable.h</title>
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
<h1 style="margin:8px;" id="f1">maptable.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
<span class="enscript-comment">/*	maptable.h
	Scalable hash table of mappings.
	Bertrand, August 1990
	Copyright 1990-1996 NeXT Software, Inc.
*/</span>

#<span class="enscript-reference">warning</span> <span class="enscript-variable-name">the</span> <span class="enscript-variable-name">API</span> <span class="enscript-variable-name">in</span> <span class="enscript-variable-name">this</span> <span class="enscript-variable-name">header</span> <span class="enscript-variable-name">is</span> <span class="enscript-variable-name">obsolete</span>

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">_OBJC_MAPTABLE_H_</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_OBJC_MAPTABLE_H_</span>

#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">objc</span>/<span class="enscript-variable-name">objc</span>.<span class="enscript-variable-name">h</span>&gt;

<span class="enscript-comment">/***************	Definitions		***************/</span>

    <span class="enscript-comment">/* This module allows hashing of arbitrary associations [key -&gt; value].  Keys and values must be pointers or integers, and client is responsible for allocating/deallocating this data.  A deallocation call-back is provided.
    NX_MAPNOTAKEY (-1) is used internally as a marker, and therefore keys must always be different from -1.
    As well-behaved scalable data structures, hash tables double in size when they start becoming full, thus guaranteeing both average constant time access and linear size. */</span>

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> _NXMapTable {
    <span class="enscript-comment">/* private data structure; may change */</span>
    <span class="enscript-type">const</span> <span class="enscript-type">struct</span> _NXMapTablePrototype	*prototype;
    <span class="enscript-type">unsigned</span>	count;
    <span class="enscript-type">unsigned</span>	nbBuckets;
    <span class="enscript-type">void</span>	*buckets;
} NXMapTable;

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> _NXMapTablePrototype {
    <span class="enscript-type">unsigned</span>	(*hash)(NXMapTable *, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *key);
    <span class="enscript-type">int</span>		(*isEqual)(NXMapTable *, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *key1, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *key2);
    <span class="enscript-type">void</span>	(*free)(NXMapTable *, <span class="enscript-type">void</span> *key, <span class="enscript-type">void</span> *value);
    <span class="enscript-type">int</span>		style; <span class="enscript-comment">/* reserved for future expansion; currently 0 */</span>
} NXMapTablePrototype;
    
    <span class="enscript-comment">/* invariants assumed by the implementation: 
	A - key != -1
	B - key1 == key2 =&gt; hash(key1) == hash(key2)
	    when key varies over time, hash(key) must remain invariant
	    e.g. if string key, the string must not be changed
	C - isEqual(key1, key2) =&gt; key1 == key2
    */</span>

#<span class="enscript-reference">define</span> <span class="enscript-variable-name">NX_MAPNOTAKEY</span>	((void *)(-1))

<span class="enscript-comment">/***************	Functions		***************/</span>

OBJC_EXPORT NXMapTable *<span class="enscript-function-name">NXCreateMapTableFromZone</span>(NXMapTablePrototype prototype, <span class="enscript-type">unsigned</span> capacity, <span class="enscript-type">void</span> *z);
OBJC_EXPORT NXMapTable *<span class="enscript-function-name">NXCreateMapTable</span>(NXMapTablePrototype prototype, <span class="enscript-type">unsigned</span> capacity);
    <span class="enscript-comment">/* capacity is only a hint; 0 creates a small table */</span>

OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">NXFreeMapTable</span>(NXMapTable *table);
    <span class="enscript-comment">/* call free for each pair, and recovers table */</span>
	
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">NXResetMapTable</span>(NXMapTable *table);
    <span class="enscript-comment">/* free each pair; keep current capacity */</span>

OBJC_EXPORT BOOL <span class="enscript-function-name">NXCompareMapTables</span>(NXMapTable *table1, NXMapTable *table2);
    <span class="enscript-comment">/* Returns YES if the two sets are equal (each member of table1 in table2, and table have same size) */</span>

OBJC_EXPORT <span class="enscript-type">unsigned</span> <span class="enscript-function-name">NXCountMapTable</span>(NXMapTable *table);
    <span class="enscript-comment">/* current number of data in table */</span>
	
OBJC_EXPORT <span class="enscript-type">void</span> *<span class="enscript-function-name">NXMapMember</span>(NXMapTable *table, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *key, <span class="enscript-type">void</span> **value);
    <span class="enscript-comment">/* return original table key or NX_MAPNOTAKEY.  If key is found, value is set */</span>
	
OBJC_EXPORT <span class="enscript-type">void</span> *<span class="enscript-function-name">NXMapGet</span>(NXMapTable *table, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *key);
    <span class="enscript-comment">/* return original corresponding value or NULL.  When NULL need be stored as value, NXMapMember can be used to test for presence */</span>
	
OBJC_EXPORT <span class="enscript-type">void</span> *<span class="enscript-function-name">NXMapInsert</span>(NXMapTable *table, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *key, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *value);
    <span class="enscript-comment">/* override preexisting pair; Return previous value or NULL. */</span>
	
OBJC_EXPORT <span class="enscript-type">void</span> *<span class="enscript-function-name">NXMapRemove</span>(NXMapTable *table, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *key);
    <span class="enscript-comment">/* previous value or NULL is returned */</span>
	
<span class="enscript-comment">/* Iteration over all elements of a table consists in setting up an iteration state and then to progress until all entries have been visited.  An example of use for counting elements in a table is:
    unsigned	count = 0;
    const MyKey	*key;
    const MyValue	*value;
    NXMapState	state = NXInitMapState(table);
    while(NXNextMapState(table, &amp;state, &amp;key, &amp;value)) {
	count++;
    }
*/</span>

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> {<span class="enscript-type">int</span> index;} NXMapState;
    <span class="enscript-comment">/* callers should not rely on actual contents of the struct */</span>

OBJC_EXPORT NXMapState <span class="enscript-function-name">NXInitMapState</span>(NXMapTable *table);

OBJC_EXPORT <span class="enscript-type">int</span> <span class="enscript-function-name">NXNextMapState</span>(NXMapTable *table, NXMapState *state, <span class="enscript-type">const</span> <span class="enscript-type">void</span> **key, <span class="enscript-type">const</span> <span class="enscript-type">void</span> **value);
    <span class="enscript-comment">/* returns 0 when all elements have been visited */</span>

<span class="enscript-comment">/***************	Conveniences		***************/</span>

OBJC_EXPORT <span class="enscript-type">const</span> NXMapTablePrototype NXPtrValueMapPrototype;
    <span class="enscript-comment">/* hashing is pointer/integer hashing;
      isEqual is identity;
      free is no-op. */</span>
OBJC_EXPORT <span class="enscript-type">const</span> NXMapTablePrototype NXStrValueMapPrototype;
    <span class="enscript-comment">/* hashing is string hashing;
      isEqual is strcmp;
      free is no-op. */</span>
OBJC_EXPORT <span class="enscript-type">const</span> NXMapTablePrototype NXObjectMapPrototype;
    <span class="enscript-comment">/* for objects; uses methods: hash, isEqual:, free, all for key. */</span>

#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* _OBJC_MAPTABLE_H_ */</span>
</pre>
<hr />
</body></html>