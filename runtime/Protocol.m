<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Protocol.m</title>
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
<h1 style="margin:8px;" id="f1">Protocol.m&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
	Protocol.h
	Copyright 1991-1996 NeXT Software, Inc.
*/

#<span class="enscript-keyword">if</span> defined(WIN32)
    #include &lt;winnt-pdo.h&gt;
#endif

#include &quot;objc-private.h&quot;
#import &lt;objc/Protocol.h&gt;

#include &lt;objc/objc-runtime.h&gt;
#include &lt;stdlib.h&gt;

#<span class="enscript-keyword">if</span> defined(__MACH__) 
    #include &lt;mach-o/dyld.h&gt;
    #include &lt;mach-o/ldsyms.h&gt;
#endif 

/* some forward declarations */

static struct objc_method_description *
lookup_method(struct objc_method_description_list *mlist, SEL aSel);

static struct objc_method_description *
lookup_class_method(struct objc_protocol_list *plist, SEL aSel);

static struct objc_method_description *
lookup_instance_method(struct objc_protocol_list *plist, SEL aSel);

@implementation Protocol 


+ _fixup: (OBJC_PROTOCOL_PTR)protos numElements: (int) nentries
{
  int <span class="enscript-type">i</span>;
  <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; nentries; <span class="enscript-type">i</span>++)
    {
      /* <span class="enscript-type">isa</span> has been overloaded by the compiler to indicate <span class="enscript-type">version</span> info */
      protos<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span> OBJC_PROTOCOL_DEREF <span class="enscript-type">isa</span> = self;	// install the <span class="enscript-type">class</span> descriptor.    
    }

  <span class="enscript-keyword">return</span> self;
}

+ <span class="enscript-type">load</span>
{
  OBJC_PROTOCOL_PTR p;
  int <span class="enscript-type">size</span>;
  headerType **hp;
  headerType **hdrs;
  hdrs = _getObjcHeaders();

  <span class="enscript-keyword">for</span> (hp = hdrs; *hp; hp++) 
    {
      p = (OBJC_PROTOCOL_PTR)_getObjcProtocols((headerType*)*hp, &amp;<span class="enscript-type">size</span>);
      <span class="enscript-keyword">if</span> (p &amp;&amp; <span class="enscript-type">size</span>) { <span class="enscript-type">[</span>self _fixup:p numElements: <span class="enscript-type">size</span><span class="enscript-type">]</span>; }
    }
  free (hdrs);

  <span class="enscript-keyword">return</span> self;
}

- (BOOL) conformsTo: (Protocol *)aProtocolObj
{
  <span class="enscript-keyword">if</span> (!aProtocolObj)
    <span class="enscript-keyword">return</span> NO;

  <span class="enscript-keyword">if</span> (<span class="enscript-type">strcmp</span>(aProtocolObj-&gt;protocol_name, protocol_name) == 0)
    <span class="enscript-keyword">return</span> YES;
  <span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> (protocol_list)
    {
    int <span class="enscript-type">i</span>;
    
    <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; protocol_list-&gt;count; <span class="enscript-type">i</span>++)
      {
      Protocol *p = protocol_list-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;

      <span class="enscript-keyword">if</span> (<span class="enscript-type">strcmp</span>(aProtocolObj-&gt;protocol_name, p-&gt;protocol_name) == 0)
        <span class="enscript-keyword">return</span> YES;
   
      <span class="enscript-keyword">if</span> (<span class="enscript-type">[</span>p conformsTo:aProtocolObj<span class="enscript-type">]</span>)
	<span class="enscript-keyword">return</span> YES;
      }
    <span class="enscript-keyword">return</span> NO;
    }
  <span class="enscript-keyword">else</span>
    <span class="enscript-keyword">return</span> NO;
}

- (struct objc_method_description *) descriptionForInstanceMethod:(SEL)aSel
{
   struct objc_method_description *m = lookup_method(instance_methods, aSel);

   <span class="enscript-keyword">if</span> (!m &amp;&amp; protocol_list)
     m = lookup_instance_method(protocol_list, aSel);

   <span class="enscript-keyword">return</span> m;
}

- (struct objc_method_description *) descriptionForClassMethod:(SEL)aSel
{
   struct objc_method_description *m = lookup_method(class_methods, aSel);

   <span class="enscript-keyword">if</span> (!m &amp;&amp; protocol_list)
     m = lookup_class_method(protocol_list, aSel);

   <span class="enscript-keyword">return</span> m;
}

- (const <span class="enscript-type">char</span> *)name
{
  <span class="enscript-keyword">return</span> protocol_name;
}

- (BOOL)isEqual:other
{
    <span class="enscript-keyword">return</span> <span class="enscript-type">[</span>other isKindOf:<span class="enscript-type">[</span>Protocol <span class="enscript-type">class</span><span class="enscript-type">]</span><span class="enscript-type">]</span> &amp;&amp; <span class="enscript-type">[</span>self conformsTo: other<span class="enscript-type">]</span> &amp;&amp; <span class="enscript-type">[</span>other conformsTo: self<span class="enscript-type">]</span>;
}

- (unsigned int)hash
{
    <span class="enscript-keyword">return</span> 23;
}

static 
struct objc_method_description *
lookup_method(struct objc_method_description_list *mlist, SEL aSel)
{
   <span class="enscript-keyword">if</span> (mlist)
     {
     int <span class="enscript-type">i</span>;
     <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; mlist-&gt;count; <span class="enscript-type">i</span>++)
       <span class="enscript-keyword">if</span> (mlist-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>.name == aSel)
         <span class="enscript-keyword">return</span> mlist-&gt;list+<span class="enscript-type">i</span>;
     }
   <span class="enscript-keyword">return</span> 0;
}

static 
struct objc_method_description *
lookup_instance_method(struct objc_protocol_list *plist, SEL aSel)
{
   int <span class="enscript-type">i</span>;
   struct objc_method_description *m = 0;

   <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; plist-&gt;count; <span class="enscript-type">i</span>++)
     {
     <span class="enscript-keyword">if</span> (plist-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>-&gt;instance_methods)
       m = lookup_method(plist-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>-&gt;instance_methods, aSel);
   
     /* depth first search */  
     <span class="enscript-keyword">if</span> (!m &amp;&amp; plist-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>-&gt;protocol_list)
       m = lookup_instance_method(plist-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>-&gt;protocol_list, aSel);

     <span class="enscript-keyword">if</span> (m)
       <span class="enscript-keyword">return</span> m;
     }
   <span class="enscript-keyword">return</span> 0;
}

static 
struct objc_method_description *
lookup_class_method(struct objc_protocol_list *plist, SEL aSel)
{
   int <span class="enscript-type">i</span>;
   struct objc_method_description *m = 0;

   <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; plist-&gt;count; <span class="enscript-type">i</span>++)
     {
     <span class="enscript-keyword">if</span> (plist-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>-&gt;class_methods)
       m = lookup_method(plist-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>-&gt;class_methods, aSel);
   
     /* depth first search */  
     <span class="enscript-keyword">if</span> (!m &amp;&amp; plist-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>-&gt;protocol_list)
       m = lookup_class_method(plist-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>-&gt;protocol_list, aSel);

     <span class="enscript-keyword">if</span> (m)
       <span class="enscript-keyword">return</span> m;
     }
   <span class="enscript-keyword">return</span> 0;
}

@<span class="enscript-keyword">end</span>
</pre>
<hr />
</body></html>