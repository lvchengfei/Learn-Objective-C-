<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>hashtable2.h</title>
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
<h1 style="margin:8px;" id="f1">hashtable2.h&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
    hashtable2.h
    Scalable hash table.
    Copyright 1989-1996 NeXT Software, Inc.
*/</span>

#<span class="enscript-reference">warning</span> <span class="enscript-variable-name">the</span> <span class="enscript-variable-name">API</span> <span class="enscript-variable-name">in</span> <span class="enscript-variable-name">this</span> <span class="enscript-variable-name">header</span> <span class="enscript-variable-name">is</span> <span class="enscript-variable-name">obsolete</span>

#<span class="enscript-reference">ifndef</span> <span class="enscript-variable-name">_OBJC_LITTLE_HASHTABLE_H_</span>
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">_OBJC_LITTLE_HASHTABLE_H_</span>

#<span class="enscript-reference">import</span> &lt;<span class="enscript-variable-name">objc</span>/<span class="enscript-variable-name">objc</span>.<span class="enscript-variable-name">h</span>&gt;

<span class="enscript-comment">/*************************************************************************
 *	Hash tables of arbitrary data
 *************************************************************************/</span>

<span class="enscript-comment">/* This module allows hashing of arbitrary data.  Such data must be pointers or integers, and client is responsible for allocating/deallocating this data.  A deallocation call-back is provided.
The objective C class HashTable is prefered when dealing with (key, values) associations because it is easier to use in that situation.
As well-behaved scalable data structures, hash tables double in size when they start becoming full, thus guaranteeing both average constant time access and linear size. */</span>

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> {
    uarith_t	(*hash)(<span class="enscript-type">const</span> <span class="enscript-type">void</span> *info, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data);
    <span class="enscript-type">int</span>		(*isEqual)(<span class="enscript-type">const</span> <span class="enscript-type">void</span> *info, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data1, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data2);
    <span class="enscript-type">void</span>	(*free)(<span class="enscript-type">const</span> <span class="enscript-type">void</span> *info, <span class="enscript-type">void</span> *data);
    <span class="enscript-type">int</span>		style; <span class="enscript-comment">/* reserved for future expansion; currently 0 */</span>
    } NXHashTablePrototype;
    
<span class="enscript-comment">/* the info argument allows a certain generality, such as freeing according to some owner information */</span>
<span class="enscript-comment">/* invariants assumed by the implementation: 
	1 - data1 = data2 =&gt; hash(data1) = hash(data2)
	    when data varies over time, hash(data) must remain invariant
		    e.g. if data hashes over a string key, the string must not be changed
	2- isEqual (data1, data2) =&gt; data1= data2
 */</span>

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> {
    <span class="enscript-type">const</span> NXHashTablePrototype	*prototype;
    <span class="enscript-type">unsigned</span>			count;
    <span class="enscript-type">unsigned</span>			nbBuckets;
    <span class="enscript-type">void</span>			*buckets;
    <span class="enscript-type">const</span> <span class="enscript-type">void</span>			*info;
   } NXHashTable;
    <span class="enscript-comment">/* private data structure; may change */</span>
    
OBJC_EXPORT NXHashTable *<span class="enscript-function-name">NXCreateHashTableFromZone</span> (NXHashTablePrototype prototype, <span class="enscript-type">unsigned</span> capacity, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *info, <span class="enscript-type">void</span> *z);
OBJC_EXPORT NXHashTable *<span class="enscript-function-name">NXCreateHashTable</span> (NXHashTablePrototype prototype, <span class="enscript-type">unsigned</span> capacity, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *info);
    <span class="enscript-comment">/* if hash is 0, pointer hash is assumed */</span>
    <span class="enscript-comment">/* if isEqual is 0, pointer equality is assumed */</span>
    <span class="enscript-comment">/* if free is 0, elements are not freed */</span>
    <span class="enscript-comment">/* capacity is only a hint; 0 creates a small table */</span>
    <span class="enscript-comment">/* info allows call backs to be very general */</span>

OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">NXFreeHashTable</span> (NXHashTable *table);
    <span class="enscript-comment">/* calls free for each data, and recovers table */</span>
	
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">NXEmptyHashTable</span> (NXHashTable *table);
    <span class="enscript-comment">/* does not deallocate table nor data; keeps current capacity */</span>

OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">NXResetHashTable</span> (NXHashTable *table);
    <span class="enscript-comment">/* frees each entry; keeps current capacity */</span>

OBJC_EXPORT BOOL <span class="enscript-function-name">NXCompareHashTables</span> (NXHashTable *table1, NXHashTable *table2);
    <span class="enscript-comment">/* Returns YES if the two sets are equal (each member of table1 in table2, and table have same size) */</span>

OBJC_EXPORT NXHashTable *<span class="enscript-function-name">NXCopyHashTable</span> (NXHashTable *table);
    <span class="enscript-comment">/* makes a fresh table, copying data pointers, not data itself.  */</span>
	
OBJC_EXPORT <span class="enscript-type">unsigned</span> <span class="enscript-function-name">NXCountHashTable</span> (NXHashTable *table);
    <span class="enscript-comment">/* current number of data in table */</span>
	
OBJC_EXPORT <span class="enscript-type">int</span> <span class="enscript-function-name">NXHashMember</span> (NXHashTable *table, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data);
    <span class="enscript-comment">/* returns non-0 iff data is present in table.
    Example of use when the hashed data is a struct containing the key,
    and when the callee only has a key:
	MyStruct	pseudo;
	pseudo.key = myKey;
	return NXHashMember (myTable, &amp;pseudo)
    */</span>
	
OBJC_EXPORT <span class="enscript-type">void</span> *<span class="enscript-function-name">NXHashGet</span> (NXHashTable *table, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data);
    <span class="enscript-comment">/* return original table data or NULL.
    Example of use when the hashed data is a struct containing the key,
    and when the callee only has a key:
	MyStruct	pseudo;
	MyStruct	*original;
	pseudo.key = myKey;
	original = NXHashGet (myTable, &amp;pseudo)
    */</span>
	
OBJC_EXPORT <span class="enscript-type">void</span> *<span class="enscript-function-name">NXHashInsert</span> (NXHashTable *table, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data);
    <span class="enscript-comment">/* previous data or NULL is returned. */</span>
	
OBJC_EXPORT <span class="enscript-type">void</span> *<span class="enscript-function-name">NXHashInsertIfAbsent</span> (NXHashTable *table, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data);
    <span class="enscript-comment">/* If data already in table, returns the one in table
    else adds argument to table and returns argument. */</span>

OBJC_EXPORT <span class="enscript-type">void</span> *<span class="enscript-function-name">NXHashRemove</span> (NXHashTable *table, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data);
    <span class="enscript-comment">/* previous data or NULL is returned */</span>
	
<span class="enscript-comment">/* Iteration over all elements of a table consists in setting up an iteration state and then to progress until all entries have been visited.  An example of use for counting elements in a table is:
    unsigned	count = 0;
    MyData	*data;
    NXHashState	state = NXInitHashState(table);
    while (NXNextHashState(table, &amp;state, &amp;data)) {
	count++;
    }
*/</span>

<span class="enscript-type">typedef</span> <span class="enscript-type">struct</span> {<span class="enscript-type">int</span> i; <span class="enscript-type">int</span> j;} NXHashState;
    <span class="enscript-comment">/* callers should not rely on actual contents of the struct */</span>

OBJC_EXPORT NXHashState <span class="enscript-function-name">NXInitHashState</span>(NXHashTable *table);

OBJC_EXPORT <span class="enscript-type">int</span> <span class="enscript-function-name">NXNextHashState</span>(NXHashTable *table, NXHashState *state, <span class="enscript-type">void</span> **data);
    <span class="enscript-comment">/* returns 0 when all elements have been visited */</span>

<span class="enscript-comment">/*************************************************************************
 *	Conveniences for writing hash, isEqual and free functions
 *	and common prototypes
 *************************************************************************/</span>

OBJC_EXPORT uarith_t <span class="enscript-function-name">NXPtrHash</span>(<span class="enscript-type">const</span> <span class="enscript-type">void</span> *info, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data);
    <span class="enscript-comment">/* scrambles the address bits; info unused */</span>
OBJC_EXPORT uarith_t <span class="enscript-function-name">NXStrHash</span>(<span class="enscript-type">const</span> <span class="enscript-type">void</span> *info, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data);
    <span class="enscript-comment">/* string hashing; info unused */</span>
OBJC_EXPORT <span class="enscript-type">int</span> <span class="enscript-function-name">NXPtrIsEqual</span>(<span class="enscript-type">const</span> <span class="enscript-type">void</span> *info, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data1, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data2);
    <span class="enscript-comment">/* pointer comparison; info unused */</span>
OBJC_EXPORT <span class="enscript-type">int</span> <span class="enscript-function-name">NXStrIsEqual</span>(<span class="enscript-type">const</span> <span class="enscript-type">void</span> *info, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data1, <span class="enscript-type">const</span> <span class="enscript-type">void</span> *data2);
    <span class="enscript-comment">/* string comparison; NULL ok; info unused */</span>
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">NXNoEffectFree</span>(<span class="enscript-type">const</span> <span class="enscript-type">void</span> *info, <span class="enscript-type">void</span> *data);
    <span class="enscript-comment">/* no effect; info unused */</span>
OBJC_EXPORT <span class="enscript-type">void</span> <span class="enscript-function-name">NXReallyFree</span>(<span class="enscript-type">const</span> <span class="enscript-type">void</span> *info, <span class="enscript-type">void</span> *data);
    <span class="enscript-comment">/* frees it; info unused */</span>

<span class="enscript-comment">/* The two following prototypes are useful for manipulating set of pointers or set of strings; For them free is defined as NXNoEffectFree */</span>
OBJC_EXPORT <span class="enscript-type">const</span> NXHashTablePrototype NXPtrPrototype;
    <span class="enscript-comment">/* prototype when data is a pointer (void *) */</span>
OBJC_EXPORT <span class="enscript-type">const</span> NXHashTablePrototype NXStrPrototype;
    <span class="enscript-comment">/* prototype when data is a string (char *) */</span>

<span class="enscript-comment">/* following prototypes help describe mappings where the key is the first element of a struct and is either a pointer or a string.
For example NXStrStructKeyPrototype can be used to hash pointers to Example, where Example is:
	typedef struct {
	    char	*key;
	    int		data1;
	    ...
	    } Example
    
For the following prototypes, free is defined as NXReallyFree.
 */</span>
OBJC_EXPORT <span class="enscript-type">const</span> NXHashTablePrototype NXPtrStructKeyPrototype;
OBJC_EXPORT <span class="enscript-type">const</span> NXHashTablePrototype NXStrStructKeyPrototype;

<span class="enscript-comment">/*************************************************************************
 *	Unique strings and buffers
 *************************************************************************/</span>

<span class="enscript-comment">/* Unique strings allows C users to enjoy the benefits of Lisp's atoms:
A unique string is a string that is allocated once for all (never de-allocated) and that has only one representant (thus allowing comparison with == instead of strcmp).  A unique string should never be modified (and in fact some memory protection is done to ensure that).  In order to more explicitly insist on the fact that the string has been uniqued, a synonym of (const char *) has been added, NXAtom. */</span>

<span class="enscript-type">typedef</span> <span class="enscript-type">const</span> <span class="enscript-type">char</span> *NXAtom;

OBJC_EXPORT NXAtom <span class="enscript-function-name">NXUniqueString</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *buffer);
    <span class="enscript-comment">/* assumes that buffer is \0 terminated, and returns
     a previously created string or a new string that is a copy of buffer.
    If NULL is passed returns NULL.
    Returned string should never be modified.  To ensure this invariant,
    allocations are made in a special read only zone. */</span>
	
OBJC_EXPORT NXAtom <span class="enscript-function-name">NXUniqueStringWithLength</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *buffer, <span class="enscript-type">int</span> length);
    <span class="enscript-comment">/* assumes that buffer is a non NULL buffer of at least 
    length characters.  Returns a previously created string or 
    a new string that is a copy of buffer. 
    If buffer contains \0, string will be truncated.
    As for NXUniqueString, returned string should never be modified.  */</span>
	
OBJC_EXPORT NXAtom <span class="enscript-function-name">NXUniqueStringNoCopy</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *string);
    <span class="enscript-comment">/* If there is already a unique string equal to string, returns the original.  
    Otherwise, string is entered in the table, without making a copy.  Argument should then never be modified.  */</span>
	
OBJC_EXPORT <span class="enscript-type">char</span> *<span class="enscript-function-name">NXCopyStringBuffer</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *buffer);
    <span class="enscript-comment">/* given a buffer, allocates a new string copy of buffer.  
    Buffer should be \0 terminated; returned string is \0 terminated. */</span>

OBJC_EXPORT <span class="enscript-type">char</span> *<span class="enscript-function-name">NXCopyStringBufferFromZone</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *buffer, <span class="enscript-type">void</span> *z);
    <span class="enscript-comment">/* given a buffer, allocates a new string copy of buffer.  
    Buffer should be \0 terminated; returned string is \0 terminated. */</span>

#<span class="enscript-reference">endif</span> <span class="enscript-comment">/* _OBJC_LITTLE_HASHTABLE_H_ */</span>
</pre>
<hr />
</body></html>