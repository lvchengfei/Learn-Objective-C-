<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc_hpux_register_shlib.c</title>
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
<h1 style="margin:8px;" id="f1">objc_hpux_register_shlib.c&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
 *      objc_hpux_register_shlib.c
 *      Author: Laurent Ramontianu
 */</span>

#<span class="enscript-reference">warning</span> <span class="enscript-string">&quot;OBJC SHLIB SUPPORT WARNING:&quot;</span>
#<span class="enscript-reference">warning</span> <span class="enscript-string">&quot;Compiling objc_hpux_register_shlib.c&quot;</span>
#<span class="enscript-reference">warning</span> <span class="enscript-string">&quot;Shlibs containing objc code must be built using&quot;</span>
#<span class="enscript-reference">warning</span> <span class="enscript-string">&quot;the ld option: +I'objc_hpux_register_shlib_$(NAME)'&quot;</span>
#<span class="enscript-reference">warning</span> <span class="enscript-string">&quot;Be advised that if collect isn't fixed to ignore&quot;</span>
#<span class="enscript-reference">warning</span> <span class="enscript-string">&quot;shlibs, your app may (and will) CRASH!!!&quot;</span>

#<span class="enscript-reference">include</span> <span class="enscript-string">&lt;dl.h&gt;</span>
#<span class="enscript-reference">include</span> <span class="enscript-string">&lt;stdlib.h&gt;</span>
#<span class="enscript-reference">include</span> <span class="enscript-string">&lt;stdio.h&gt;</span>
#<span class="enscript-reference">include</span> <span class="enscript-string">&lt;string.h&gt;</span>
#<span class="enscript-reference">include</span> <span class="enscript-string">&lt;fcntl.h&gt;</span>
#<span class="enscript-reference">include</span> <span class="enscript-string">&lt;sys/mman.h&gt;</span>
#<span class="enscript-reference">include</span> <span class="enscript-string">&lt;sys/unistd.h&gt;</span>
#<span class="enscript-reference">include</span> <span class="enscript-string">&lt;sys/stat.h&gt;</span>

<span class="enscript-type">static</span> <span class="enscript-type">char</span> *_loaded_shlibs_init[128] = {
        <span class="enscript-string">&quot;java&quot;</span>,
        <span class="enscript-string">&quot;cl&quot;</span>,
        <span class="enscript-string">&quot;isamstub&quot;</span>,
        <span class="enscript-string">&quot;c&quot;</span>,
        <span class="enscript-string">&quot;m&quot;</span>,
        <span class="enscript-string">&quot;dld&quot;</span>,
        <span class="enscript-string">&quot;gen&quot;</span>,
        <span class="enscript-string">&quot;pthread&quot;</span>,
        <span class="enscript-string">&quot;lwp&quot;</span>
};

<span class="enscript-type">static</span> <span class="enscript-type">unsigned</span> _loaded_shlibs_size = 128;
<span class="enscript-type">static</span> <span class="enscript-type">unsigned</span> _loaded_shlibs_count = 9;

<span class="enscript-type">static</span> <span class="enscript-type">char</span> **_loaded_shlibs = _loaded_shlibs_init;

<span class="enscript-type">static</span> <span class="enscript-type">void</span> <span class="enscript-function-name">dump_loaded_shlibs</span>() {
    <span class="enscript-type">int</span> i;
    printf(<span class="enscript-string">&quot;****    Loaded shlibs    ****\n&quot;</span>);
    <span class="enscript-keyword">for</span> ( i=0; i&lt;_loaded_shlibs_count; i++ ) {
        printf(<span class="enscript-string">&quot;\t%s\n&quot;</span>, _loaded_shlibs[i]);
    }
    printf(<span class="enscript-string">&quot;---                      ----\n&quot;</span>);
}


<span class="enscript-type">static</span> <span class="enscript-type">char</span> *<span class="enscript-function-name">my_basename</span>(<span class="enscript-type">char</span> *path)
{
    <span class="enscript-type">char</span> *res = 0;
    <span class="enscript-type">unsigned</span> idx = strlen(path) - 1;

    <span class="enscript-keyword">if</span> ( path[idx] == <span class="enscript-string">'/'</span> ) idx--;
    <span class="enscript-keyword">for</span> ( ; (idx &gt; 0) &amp;&amp; (path[idx] != <span class="enscript-string">'/'</span>) ; idx-- ) {
        <span class="enscript-keyword">if</span> ( path[idx] == <span class="enscript-string">'.'</span> ) path[idx] = '\000';
    }
    <span class="enscript-keyword">if</span> ( path[idx] == <span class="enscript-string">'/'</span>) idx++;
    res = strstr(&amp;path[idx], <span class="enscript-string">&quot;lib&quot;</span>);
    <span class="enscript-keyword">if</span> ( !res ) {
        <span class="enscript-keyword">return</span> &amp;path[idx];
    }
    <span class="enscript-keyword">if</span> ( res == &amp;path[idx] ) {
        <span class="enscript-keyword">return</span> &amp;path[idx+3];
    }
    <span class="enscript-keyword">return</span> &amp;path[idx];
}


<span class="enscript-type">extern</span> <span class="enscript-type">void</span> *<span class="enscript-function-name">malloc</span>(<span class="enscript-type">unsigned</span>);
<span class="enscript-type">extern</span> <span class="enscript-type">void</span>  <span class="enscript-function-name">free</span>(<span class="enscript-type">void</span> *);

<span class="enscript-comment">// Hooks if we decide to provide alternate malloc/free functions
</span><span class="enscript-type">static</span> <span class="enscript-type">void</span>*(*_malloc_ptr)(<span class="enscript-type">unsigned</span>) = malloc;
<span class="enscript-type">static</span> <span class="enscript-function-name">void</span>(*_free_ptr)(<span class="enscript-type">void</span>*) = free;


<span class="enscript-type">static</span> <span class="enscript-type">char</span> *dep_shlibs_temp[128];
<span class="enscript-type">static</span> <span class="enscript-type">unsigned</span> dep_shlibs_temp_count = 0;

<span class="enscript-type">static</span> <span class="enscript-type">void</span> <span class="enscript-function-name">dump_dependent_shlibs</span>() {
    <span class="enscript-type">int</span> i;
    printf(<span class="enscript-string">&quot;****    Dependent shlibs    ****\n&quot;</span>);
    <span class="enscript-keyword">for</span> ( i=0; i&lt;dep_shlibs_temp_count; i++ ) {
        printf(<span class="enscript-string">&quot;\t%s\n&quot;</span>, dep_shlibs_temp[i]);
    }
    printf(<span class="enscript-string">&quot;---                      ----\n&quot;</span>);
}


<span class="enscript-type">static</span> <span class="enscript-type">void</span> <span class="enscript-function-name">init_dependent_shlibs</span>(<span class="enscript-type">char</span> *name)
{
    dep_shlibs_temp[0] = name;
    dep_shlibs_temp_count = 1;
}


<span class="enscript-type">static</span> <span class="enscript-type">int</span> <span class="enscript-function-name">already_loaded</span>(<span class="enscript-type">char</span> *path);

<span class="enscript-type">static</span> <span class="enscript-type">void</span> <span class="enscript-function-name">insert_dependent_shlib</span>(<span class="enscript-type">char</span> *path)
{
    <span class="enscript-keyword">if</span> ( ! already_loaded(path) ) {
        dep_shlibs_temp[dep_shlibs_temp_count] = path;
        dep_shlibs_temp_count++;
        <span class="enscript-keyword">return</span>;
    }
}

<span class="enscript-type">static</span> <span class="enscript-type">char</span> **<span class="enscript-function-name">dependent_shlibs</span>()
{
    <span class="enscript-type">unsigned</span> size;
    <span class="enscript-type">unsigned</span> idx;
    <span class="enscript-type">char</span> *ptr;
    <span class="enscript-type">char</span> *name;
    <span class="enscript-type">unsigned</span> ref_size;

    insert_dependent_shlib(<span class="enscript-string">&quot;&lt;NULL&gt;&quot;</span>);

    size = 0;
    <span class="enscript-keyword">for</span> ( idx = 0; idx &lt; dep_shlibs_temp_count; idx++ ) {
        size += <span class="enscript-keyword">sizeof</span>(<span class="enscript-type">char</span>*) + strlen(dep_shlibs_temp[idx]) + 1;
    }

    <span class="enscript-keyword">if</span> ( ! (ptr = _malloc_ptr(size)) ) {
        fprintf(stderr, <span class="enscript-string">&quot;dependent_shlibs: fatal - malloc() failed\n&quot;</span>);
        exit(-1);
    }

    ref_size = dep_shlibs_temp_count * <span class="enscript-keyword">sizeof</span>(<span class="enscript-type">char</span>*);
    size = 0;
    <span class="enscript-keyword">for</span> ( idx = 0; idx &lt; dep_shlibs_temp_count; idx++ ) {
        name = ptr + ref_size + size;
        *((<span class="enscript-type">char</span> **)ptr + idx) = name;
        strcpy(name, dep_shlibs_temp[idx]);
        size += strlen(name) + 1;
    }

    dep_shlibs_temp_count = 0;
    <span class="enscript-keyword">return</span> (<span class="enscript-type">char</span> **)ptr;
}


<span class="enscript-type">static</span> <span class="enscript-type">char</span> **<span class="enscript-function-name">__objc_get_referenced_shlibs</span>(<span class="enscript-type">char</span> *path)
{
    <span class="enscript-type">static</span> <span class="enscript-type">char</span> **dict[128];
    <span class="enscript-type">static</span> <span class="enscript-type">unsigned</span> dict_size = 0;
    <span class="enscript-type">static</span> <span class="enscript-type">char</span> *res_nil[] = { <span class="enscript-string">&quot;&lt;NULL&gt;&quot;</span> };
    <span class="enscript-type">static</span> <span class="enscript-type">char</span> file_name[48];

    <span class="enscript-type">int</span> fd;
    <span class="enscript-type">int</span> child_pid;
    <span class="enscript-type">unsigned</span> <span class="enscript-type">long</span> size;
    <span class="enscript-type">void</span> *addr;

    <span class="enscript-type">char</span> *ptr;
    <span class="enscript-type">char</span> *ptr2;
    <span class="enscript-type">char</span> buf[256], *name;
    <span class="enscript-type">unsigned</span> idx;

    strcpy(buf, path);
    name = my_basename(buf);

    <span class="enscript-keyword">for</span> (idx = 0; idx &lt; dict_size; idx++ ) {
        <span class="enscript-keyword">if</span> ( ! strcmp(name, *(dict[idx])) )
            <span class="enscript-keyword">return</span> dict[idx]+1;
    }

    child_pid = vfork();
    <span class="enscript-keyword">if</span> ( child_pid &lt; 0 ) {
        fprintf(stderr, <span class="enscript-string">&quot;__objc_get_referenced_shlibs: fatal - vfork() failed\n&quot;</span>);
        exit(-1);
    }

    <span class="enscript-keyword">if</span> ( child_pid &gt; 0 ) {
        wait(0);
        sprintf(file_name, <span class="enscript-string">&quot;/tmp/apple_shlib_reg.%d&quot;</span>, child_pid);
        <span class="enscript-keyword">if</span> ( (fd = open(file_name, O_RDONLY)) &lt; 0 ) {
            fprintf(stderr, <span class="enscript-string">&quot;__objc_get_referenced_shlibs: fatal - open() failed\n&quot;</span>);
            exit(-1);
        }
        size = lseek(fd, 0, SEEK_END);
        addr = mmap(0, size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);

        init_dependent_shlibs(name);
        <span class="enscript-keyword">if</span> ( ptr = strstr(addr, <span class="enscript-string">&quot;list:&quot;</span>) ) {
            ptr2 = strtok(ptr, <span class="enscript-string">&quot; \n\t&quot;</span>);
            <span class="enscript-keyword">for</span> ( ; ; ) {
                ptr2 = strtok(0, <span class="enscript-string">&quot; \n\t&quot;</span>);
                <span class="enscript-keyword">if</span> ( ! ptr2 || strcmp(ptr2, <span class="enscript-string">&quot;dynamic&quot;</span>) ) <span class="enscript-keyword">break</span>;
                ptr2 = strtok(0, <span class="enscript-string">&quot; \n\t&quot;</span>);
                <span class="enscript-keyword">if</span> ( ! ptr2 ) {
                    fprintf(stderr, <span class="enscript-string">&quot;__objc_get_referenced_shlibs: fatal - %s has bad format\n&quot;</span>, file_name);
                    exit(-1);
                }
                insert_dependent_shlib(ptr2);
            }
        }

        dict[dict_size] = dependent_shlibs();
        munmap(addr, size);
        close(fd);
        unlink(file_name);
        <span class="enscript-keyword">return</span> dict[dict_size++];
    }
    <span class="enscript-keyword">else</span> {
        sprintf(file_name, <span class="enscript-string">&quot;/tmp/apple_shlib_reg.%d&quot;</span>, getpid());
        close(1);
        <span class="enscript-keyword">if</span> ( open(file_name, O_WRONLY | O_CREAT, 0) &lt; 0 ) { exit(-1); }
<span class="enscript-comment">// Uncomment next 2 lines if it's needed to redirect stderr as well
</span><span class="enscript-comment">/*
        close(2);
        dup(1);
*/</span>
        <span class="enscript-comment">/* aB. For some reason the file seems to be created with no read permission if done as a normal user */</span>
        chmod(file_name, S_IRUSR | S_IRGRP | S_IROTH);
        execl(<span class="enscript-string">&quot;/usr/bin/chatr&quot;</span>, <span class="enscript-string">&quot;chatr&quot;</span>, path, 0);
        fprintf(stderr, <span class="enscript-string">&quot;__objc_get_referenced_shlibs: failed to exec chatr\n&quot;</span>);
        exit(-1);
    }

    <span class="enscript-keyword">return</span> res_nil;
}


<span class="enscript-type">static</span> <span class="enscript-type">int</span> _verbose = -1;
<span class="enscript-type">static</span> <span class="enscript-type">int</span> _reg_mechanism = -1;

#<span class="enscript-reference">define</span> <span class="enscript-variable-name">OBJC_SHLIB_INIT_REGISTRATION</span> if (_reg_mechanism == -1) {registration_init();}
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">REG_METHOD_CHATR</span> 0
#<span class="enscript-reference">define</span> <span class="enscript-variable-name">REG_METHOD_DLD</span> 1

<span class="enscript-type">static</span> <span class="enscript-type">void</span> <span class="enscript-function-name">registration_init</span>() {
    <span class="enscript-type">const</span> <span class="enscript-type">char</span> *str_value = getenv(<span class="enscript-string">&quot;OBJC_SHOW_SHLIB_REGISTRATION&quot;</span>);
    <span class="enscript-keyword">if</span> ( str_value ) {
        <span class="enscript-keyword">if</span>      ( !strcmp(str_value, <span class="enscript-string">&quot;ALL&quot;</span>) )   _verbose = 4;
        <span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> ( !strcmp(str_value, <span class="enscript-string">&quot;LIBS&quot;</span>) )  _verbose = 1;
        <span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> ( !strcmp(str_value, <span class="enscript-string">&quot;LIST&quot;</span>) )  _verbose = 2;
        <span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> ( !strcmp(str_value, <span class="enscript-string">&quot;CTORS&quot;</span>) ) _verbose = 3;
        <span class="enscript-keyword">else</span> _verbose = 0;
    }
    <span class="enscript-keyword">else</span> _verbose = 0;

    str_value = getenv(<span class="enscript-string">&quot;OBJC_SHLIB_REGISTRATION_METHOD&quot;</span>);
    <span class="enscript-keyword">if</span> ( str_value ) {
        <span class="enscript-keyword">if</span>      ( !strcmp(str_value, <span class="enscript-string">&quot;DLD&quot;</span>) ) _reg_mechanism = REG_METHOD_DLD;
        <span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> ( !strcmp(str_value, <span class="enscript-string">&quot;AB&quot;</span>) )  _reg_mechanism = REG_METHOD_DLD;
        <span class="enscript-keyword">else</span> <span class="enscript-keyword">if</span> ( !strcmp(str_value, <span class="enscript-string">&quot;NEW&quot;</span>) ) _reg_mechanism = REG_METHOD_DLD;
        <span class="enscript-keyword">else</span> _reg_mechanism = REG_METHOD_CHATR;
    }
    <span class="enscript-keyword">else</span> _reg_mechanism = REG_METHOD_DLD;

    <span class="enscript-keyword">if</span> (_verbose &gt; 0) {
        <span class="enscript-keyword">if</span> (_reg_mechanism == REG_METHOD_CHATR) {
            fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_shlib(): Using old (chatr) registration method\n&quot;</span>);
        } <span class="enscript-keyword">else</span> {
            fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_shlib(): Using new (dld) registration method\n&quot;</span>);
        }
    }
}


<span class="enscript-type">static</span> <span class="enscript-type">void</span> <span class="enscript-function-name">insert_loaded_shlib</span>(<span class="enscript-type">char</span> *path);

<span class="enscript-type">static</span> <span class="enscript-type">int</span> <span class="enscript-function-name">already_loaded</span>(<span class="enscript-type">char</span> *path)
{
    <span class="enscript-type">static</span> <span class="enscript-type">int</span> first_time_here = 1;
    <span class="enscript-type">unsigned</span> idx;
    <span class="enscript-type">char</span> buf[256], *name;
    
    strcpy(buf, path);
    name = my_basename(buf);

    OBJC_SHLIB_INIT_REGISTRATION;

    <span class="enscript-keyword">for</span> ( idx = 0; idx &lt; _loaded_shlibs_count; idx++ ) {
        <span class="enscript-keyword">if</span> ( ! strcmp(_loaded_shlibs[idx], name) ) {
            <span class="enscript-keyword">return</span> 1;
        }
    }

    <span class="enscript-keyword">if</span> ( first_time_here ) { <span class="enscript-comment">// the root executable is the first shlib(sic)
</span>        first_time_here = 0;
        insert_loaded_shlib(path);
        <span class="enscript-keyword">return</span> 1;
    }

    <span class="enscript-keyword">return</span> 0;
}

<span class="enscript-type">static</span> <span class="enscript-type">void</span> <span class="enscript-function-name">insert_loaded_shlib</span>(<span class="enscript-type">char</span> *path)
{
    <span class="enscript-type">char</span> **_loaded_shlibs_temp;
    <span class="enscript-type">char</span> buf[256], *name;

    strcpy(buf, path);
    name = my_basename(buf);

    <span class="enscript-keyword">if</span> ( already_loaded(path) ) {
        <span class="enscript-keyword">return</span>;
    }
    <span class="enscript-keyword">if</span> ( _loaded_shlibs_count &gt;= _loaded_shlibs_size ) {
        _loaded_shlibs_temp = _loaded_shlibs;
        _loaded_shlibs_size += 32;
        _loaded_shlibs = (<span class="enscript-type">char</span> **)_malloc_ptr(_loaded_shlibs_size*<span class="enscript-keyword">sizeof</span>(<span class="enscript-type">char</span> *));
        <span class="enscript-keyword">if</span> ( ! _loaded_shlibs ) {
            fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_shlib() - fatal: Failed to malloc _loaded_shlibs list. Exit\n&quot;</span>);
            exit(-1);
        }
        memcpy(_loaded_shlibs, _loaded_shlibs_temp, _loaded_shlibs_count);
        <span class="enscript-keyword">if</span> ( _loaded_shlibs_temp != _loaded_shlibs_init ) {
            _free_ptr(_loaded_shlibs_temp);
        }
    }

    <span class="enscript-keyword">if</span> ( ! (_loaded_shlibs[_loaded_shlibs_count] = _malloc_ptr(strlen(name)+1)) ) {
        fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_shlib() - fatal: Failed to malloc _loaded_shlibs entry. Exit\n&quot;</span>);
        exit(-1);
    }
    strcpy(_loaded_shlibs[_loaded_shlibs_count++], name);
    <span class="enscript-keyword">return</span>;
}


<span class="enscript-type">static</span> <span class="enscript-type">char</span> *_pending_shlibs_init[128] = { <span class="enscript-string">&quot;nhnd&lt;NULL&gt;&quot;</span> };

<span class="enscript-type">static</span> <span class="enscript-type">unsigned</span> _pending_shlibs_size = 128;
<span class="enscript-type">static</span> <span class="enscript-type">unsigned</span> _pending_shlibs_count = 1;

<span class="enscript-type">static</span> <span class="enscript-type">char</span> **_pending_shlibs = _pending_shlibs_init;

<span class="enscript-type">static</span> <span class="enscript-type">void</span> <span class="enscript-function-name">dump_pending_shlibs</span>() {
    <span class="enscript-type">int</span> i;
    printf(<span class="enscript-string">&quot;****    Pending shlibs    ****\n&quot;</span>);
    <span class="enscript-keyword">for</span> ( i=0; i&lt;_pending_shlibs_count; i++ ) {
        printf(<span class="enscript-string">&quot;\t%s\n&quot;</span>, _pending_shlibs[i]+<span class="enscript-keyword">sizeof</span>(<span class="enscript-type">void</span>*));
    }
    printf(<span class="enscript-string">&quot;---                      ----\n&quot;</span>);
}


<span class="enscript-type">static</span> <span class="enscript-type">int</span> <span class="enscript-function-name">already_pending</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *path)
{
    <span class="enscript-type">unsigned</span> idx;
    <span class="enscript-keyword">for</span> ( idx = 0; idx &lt; _pending_shlibs_count; idx++ ) {
        <span class="enscript-keyword">if</span> ( ! strcmp(_pending_shlibs[idx]+<span class="enscript-keyword">sizeof</span>(<span class="enscript-type">void</span>*), path) ) {
            <span class="enscript-keyword">if</span> (_verbose &gt; 1) {
                fprintf(stderr, <span class="enscript-string">&quot;already_pending(): Already pended shlib %s\n&quot;</span>, path);
            }
            <span class="enscript-keyword">return</span> 1;
        }
    }
    <span class="enscript-keyword">if</span> (_verbose &gt; 1) {
        fprintf(stderr, <span class="enscript-string">&quot;already_pending(): Pending shlib %s\n&quot;</span>, path);
    }
    <span class="enscript-keyword">return</span> 0;
}

<span class="enscript-type">static</span> <span class="enscript-type">void</span> <span class="enscript-function-name">insert_pending_shlib</span>(<span class="enscript-type">struct</span> shl_descriptor *desc)
{
    <span class="enscript-type">char</span> **_pending_shlibs_temp;
    <span class="enscript-type">char</span> *ptr;
    <span class="enscript-type">int</span> mask;

    <span class="enscript-keyword">if</span> (_verbose &gt; 1) {
        fprintf(stderr, <span class="enscript-string">&quot;insert_pending_shlib(): Inserting shlib %s\n&quot;</span>, desc-&gt;filename);
    }

    <span class="enscript-keyword">if</span> ( already_pending(desc-&gt;filename) )
        <span class="enscript-keyword">return</span>;

    <span class="enscript-keyword">if</span> ( _pending_shlibs_count &gt;= _pending_shlibs_size ) {
        _pending_shlibs_temp = _pending_shlibs;
        _pending_shlibs_size += 32;
        _pending_shlibs = (<span class="enscript-type">char</span> **)_malloc_ptr(_pending_shlibs_size*<span class="enscript-keyword">sizeof</span>(<span class="enscript-type">char</span> *));
        <span class="enscript-keyword">if</span> ( ! _pending_shlibs ) {
            fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_shlib() - fatal: Failed to malloc _pending_shlibs list. Exit\n&quot;</span>);
            exit(-1);
        }
        memcpy(_pending_shlibs, _pending_shlibs_temp, _pending_shlibs_count);
        <span class="enscript-keyword">if</span> ( _pending_shlibs_temp != _pending_shlibs_init ) {
            _free_ptr(_pending_shlibs_temp);
        }
    }

    <span class="enscript-keyword">if</span> ( ! (ptr = _malloc_ptr(strlen(desc-&gt;filename)+1+<span class="enscript-keyword">sizeof</span>(<span class="enscript-type">void</span> *)*2)) ) {
        fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_shlib() - fatal: Failed to malloc _pending_shlibs entry. Exit\n&quot;</span>);
        exit(-1);
    }
    strcpy(ptr+<span class="enscript-keyword">sizeof</span>(<span class="enscript-type">void</span>*), desc-&gt;filename);
    *(<span class="enscript-type">void</span> **)ptr = desc-&gt;handle;
    _pending_shlibs[_pending_shlibs_count] = ptr;
    <span class="enscript-keyword">return</span>;
}

<span class="enscript-type">static</span> <span class="enscript-type">void</span> <span class="enscript-function-name">delete_pending_shlib</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *path)
{
    <span class="enscript-type">unsigned</span> idx;
    <span class="enscript-type">char</span> *ptr;

    <span class="enscript-keyword">if</span> (_verbose &gt; 1) {
        fprintf(stderr, <span class="enscript-string">&quot;delete_pending_shlib(): Deleting shlib %s\n&quot;</span>, path);
    }

    <span class="enscript-keyword">for</span> ( idx = 0; idx &lt; _pending_shlibs_count; idx++ ) {
        ptr = _pending_shlibs[idx]+<span class="enscript-keyword">sizeof</span>(<span class="enscript-type">void</span>*);
        <span class="enscript-keyword">if</span> ( ! strcmp(ptr, path) ) {
            <span class="enscript-keyword">if</span> ( strcmp(ptr, <span class="enscript-string">&quot;&lt;NULL&gt;&quot;</span>) ) {
                _free_ptr(_pending_shlibs[idx]);
                _pending_shlibs[idx] = <span class="enscript-string">&quot;&lt;NULL&gt;&quot;</span>;
                <span class="enscript-keyword">if</span> (_verbose &gt; 1) {
                    fprintf(stderr, <span class="enscript-string">&quot;delete_pending_shlib(): Found and deleted shlib %s\n&quot;</span>, path);
                }
            }
            <span class="enscript-keyword">return</span>;
        }
    }
}

<span class="enscript-type">static</span> <span class="enscript-type">int</span> <span class="enscript-function-name">more_pending_shlibs</span>()
{
    <span class="enscript-type">unsigned</span> idx;
    <span class="enscript-type">char</span> *ptr;

    <span class="enscript-keyword">for</span> ( idx = 0; idx &lt; _pending_shlibs_count; idx++ ) {
        ptr = _pending_shlibs[idx]+<span class="enscript-keyword">sizeof</span>(<span class="enscript-type">void</span>*);
        <span class="enscript-keyword">if</span> ( strcmp(ptr, <span class="enscript-string">&quot;&lt;NULL&gt;&quot;</span>) ) {
            <span class="enscript-keyword">return</span> 0;
        }
    }
    <span class="enscript-keyword">if</span> (_verbose &gt; 1) {
        fprintf(stderr, <span class="enscript-string">&quot;more_pending_shlib(): Pending shlibs remain\n&quot;</span>);
    }
    <span class="enscript-keyword">return</span> 1;
}


<span class="enscript-type">static</span> <span class="enscript-type">int</span> <span class="enscript-function-name">dependencies_resolved</span>(<span class="enscript-type">char</span> *path)
{
    <span class="enscript-type">char</span> **referenced_shlibs;

    referenced_shlibs = __objc_get_referenced_shlibs(path);
    referenced_shlibs++;
    <span class="enscript-keyword">for</span> ( ; strcmp(*referenced_shlibs, <span class="enscript-string">&quot;&lt;NULL&gt;&quot;</span>); referenced_shlibs++ ) {
        <span class="enscript-keyword">if</span> ( !already_loaded(*referenced_shlibs) ) {
            <span class="enscript-keyword">if</span> (_verbose &gt; 1) {
                fprintf(stderr, <span class="enscript-string">&quot;dependencies_resolved(): Dependencies remaining for shlib %s\n&quot;</span>, path);
            }
            <span class="enscript-keyword">return</span> 0;
        }
    }
    <span class="enscript-keyword">if</span> (_verbose &gt; 1) {
        fprintf(stderr, <span class="enscript-string">&quot;dependencies_resolved(): Dependencies resolved for shlib %s\n&quot;</span>, path);
    }
    <span class="enscript-keyword">return</span> 1;
}


<span class="enscript-type">void</span> <span class="enscript-function-name">objc_hpux_register_shlib_handle</span>(<span class="enscript-type">void</span> *handle);

<span class="enscript-type">static</span> <span class="enscript-type">void</span> <span class="enscript-function-name">resolve_pending_shlibs</span>()
{
    <span class="enscript-type">char</span> *ptr;
    <span class="enscript-type">unsigned</span> idx;

    <span class="enscript-keyword">for</span> ( idx = 0; idx &lt; _pending_shlibs_count; idx++ ) {
        ptr = _pending_shlibs[idx]+<span class="enscript-keyword">sizeof</span>(<span class="enscript-type">void</span>*);
        <span class="enscript-keyword">if</span> ( dependencies_resolved(ptr) ) {
            <span class="enscript-keyword">if</span> ( _verbose &gt;= 1 ) {
                fprintf(stderr, <span class="enscript-string">&quot;resolve_pending_shlibs(): Examining shlib %s\n&quot;</span>, ptr);
            }
            objc_hpux_register_shlib_handle(*(<span class="enscript-type">void</span> **)_pending_shlibs[idx]);
            delete_pending_shlib(ptr);
            insert_loaded_shlib(ptr);
        }
    }
}


<span class="enscript-type">void</span> <span class="enscript-function-name">objc_hpux_register_shlib_handle</span>(<span class="enscript-type">void</span> *handle)
{
    <span class="enscript-type">extern</span> <span class="enscript-type">void</span> *CMH;
    <span class="enscript-type">extern</span> objc_finish_header();

    <span class="enscript-type">int</span> isCMHReset;
    <span class="enscript-type">int</span> sym_count, sym_idx;
    <span class="enscript-type">struct</span> shl_symbol *symbols;

    <span class="enscript-comment">// use malloc and not _malloc_ptr
</span>    sym_count = shl_getsymbols(handle, TYPE_PROCEDURE,
                        EXPORT_SYMBOLS, malloc, &amp;symbols);
    <span class="enscript-keyword">if</span> ( sym_count == -1 ) {
        fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_shlib_handle() - WARNING: shl_getsymbols failed. Continue at your own risk...\n&quot;</span>);
        <span class="enscript-comment">//exit(-1);
</span>        <span class="enscript-keyword">return</span>;
    }

    isCMHReset = 0;
    <span class="enscript-keyword">for</span> ( sym_idx = 0; sym_idx &lt; sym_count; sym_idx++ ) {
        <span class="enscript-keyword">if</span> ( !strncmp(symbols[sym_idx].name, <span class="enscript-string">&quot;_GLOBAL_$I$&quot;</span>, 11) ) {
            <span class="enscript-keyword">if</span> ( ! isCMHReset ) {
                 CMH = (<span class="enscript-type">void</span> *)0;
                 isCMHReset = 1;
            }
            <span class="enscript-keyword">if</span> ( _verbose &gt;= 3 )
                fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_shlib_handle():    found ctor %s...\n&quot;</span>, symbols[sym_idx].name);
            ((<span class="enscript-type">void</span> (*)())(symbols[sym_idx].value))();
            <span class="enscript-keyword">if</span> ( _verbose &gt;= 3 )
                fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_shlib_handle():    ... and executed it\n&quot;</span>);
        }
    }
    <span class="enscript-keyword">if</span> ( isCMHReset )
        objc_finish_header();

    <span class="enscript-comment">// use free and not _free_ptr
</span>    free(symbols);
    <span class="enscript-keyword">return</span>;
}

<span class="enscript-type">void</span> <span class="enscript-function-name">objc_hpux_register_shlib</span>()
{
    <span class="enscript-type">int</span> idx;
    <span class="enscript-type">int</span> registered_at_least_one_shlib;
    <span class="enscript-type">struct</span> shl_descriptor desc;

    OBJC_SHLIB_INIT_REGISTRATION;

    <span class="enscript-keyword">if</span> (_reg_mechanism != REG_METHOD_CHATR) <span class="enscript-keyword">return</span>;

    <span class="enscript-keyword">if</span> ( _verbose == 2 || _verbose == 4 )
        fprintf(stderr, <span class="enscript-string">&quot;----        ----\n&quot;</span>);

    registered_at_least_one_shlib = 0;
    <span class="enscript-keyword">for</span> ( idx = 0; !shl_get_r(idx, &amp;desc); idx++ ) {
        <span class="enscript-keyword">if</span> ( already_loaded(desc.filename) ) {
            <span class="enscript-keyword">if</span> ( _verbose == 2 || _verbose == 4 )
                fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_shlib(): Skipping shlib %s\n&quot;</span>, desc.filename);
            <span class="enscript-keyword">continue</span>;
        }

        <span class="enscript-keyword">if</span> ( !dependencies_resolved(desc.filename) ) {
            insert_pending_shlib(&amp;desc);
            <span class="enscript-keyword">continue</span>;
        }

        <span class="enscript-keyword">if</span> ( _verbose &gt;= 1 || _verbose == 4 )
            fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_shlib(): Examining shlib %s\n&quot;</span>, desc.filename);
        objc_hpux_register_shlib_handle(desc.handle);
        delete_pending_shlib(desc.filename);
        insert_loaded_shlib(desc.filename);
        registered_at_least_one_shlib = 1;
    }

    <span class="enscript-comment">// This is the last call and the last chance to resolve them all!
</span>    <span class="enscript-keyword">if</span> ( ! registered_at_least_one_shlib ) {
        <span class="enscript-keyword">while</span> ( more_pending_shlibs() )
            resolve_pending_shlibs();
    }

    <span class="enscript-keyword">if</span> ( _verbose == 2 || _verbose == 4)
        fprintf(stderr, <span class="enscript-string">&quot;----        ----\n\n&quot;</span>);

    <span class="enscript-keyword">return</span>;
}

<span class="enscript-comment">/*
 * An alternative, more efficient shlib registration that relies on the initializer
 * functions in each shlib being called in the correct order. This was initially deemed not to work. aB.
 */</span>
<span class="enscript-type">void</span> <span class="enscript-function-name">objc_hpux_register_named_shlib</span>(<span class="enscript-type">const</span> <span class="enscript-type">char</span> *shlib_name)
{
    <span class="enscript-type">int</span> idx;
    <span class="enscript-type">struct</span> shl_descriptor desc;
    <span class="enscript-type">char</span> buf1[256], *p1;
    <span class="enscript-type">char</span> buf2[256], *p2;

    OBJC_SHLIB_INIT_REGISTRATION;

    strcpy(buf1, shlib_name);
    p1 = my_basename(buf1);

    <span class="enscript-comment">/* Do we use the new registration method or not ? */</span>
    <span class="enscript-keyword">if</span> (_reg_mechanism == REG_METHOD_DLD) {
        <span class="enscript-keyword">if</span> ( _verbose &gt;= 1 ) {
            fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_named_shlib(): Registering shlib %s\n&quot;</span>, shlib_name);
        }
        <span class="enscript-keyword">for</span> ( idx = 0; !shl_get_r(idx, &amp;desc); idx++ ) {
            strcpy(buf2, desc.filename);
            p2 = my_basename(buf2);
            <span class="enscript-comment">/* Avoid registering the main executable (initializer == NULL) */</span>
            <span class="enscript-keyword">if</span> ( strcmp(p1, p2) == 0 &amp;&amp; desc.initializer != NULL) {
                objc_hpux_register_shlib_handle(desc.handle);
                <span class="enscript-keyword">if</span> ( _verbose &gt;= 1 ) {
                    fprintf(stderr, <span class="enscript-string">&quot;objc_hpux_register_named_shlib(): Registered shlib %s desc.initializer %x\n&quot;</span>, desc.filename, desc.initializer);
                }
                <span class="enscript-keyword">break</span>;
            }
        }
    } <span class="enscript-keyword">else</span> {
        <span class="enscript-comment">/* Just do things the old way */</span>
        objc_hpux_register_shlib();
    }

}

<span class="enscript-comment">/* Hardcoded in here for now as libpdo is built in a special manner */</span>
<span class="enscript-type">void</span> <span class="enscript-function-name">objc_hpux_register_shlib_pdo</span>()
{
    objc_hpux_register_named_shlib(<span class="enscript-string">&quot;libpdo.sl&quot;</span>);
}


<span class="enscript-type">unsigned</span> <span class="enscript-function-name">__objc_msg_spew</span>(<span class="enscript-type">unsigned</span> self_obj, <span class="enscript-type">unsigned</span> self_cls, <span class="enscript-type">unsigned</span> addr)
{
    fprintf(stderr, <span class="enscript-string">&quot;\n\n****    __objc_msg_spew(self:0x%08x  self-&gt;isa:0x%08x  cls:0x%08x)    ****\n\n&quot;</span>, self_obj, *(<span class="enscript-type">unsigned</span> *)self_obj, self_cls);
    <span class="enscript-keyword">return</span> addr;
}
</pre>
<hr />
</body></html>