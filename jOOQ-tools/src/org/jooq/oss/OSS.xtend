/**
 * Copyright (c) 2009-2013, Data Geekery GmbH (http://www.datageekery.com)
 * All rights reserved.
 *
 * This work is dual-licensed
 * - under the Apache Software License 2.0 (the "ASL")
 * - under the jOOQ License and Maintenance Agreement (the "jOOQ License")
 * =============================================================================
 * You may choose which license applies to you:
 *
 * - If you're using this work with Open Source databases, you may choose
 *   either ASL or jOOQ License.
 * - If you're using this work with at least one commercial database, you must
 *   choose jOOQ License
 *
 * For more information, please visit http://www.jooq.org/licenses
 *
 * Apache Software License 2.0:
 * -----------------------------------------------------------------------------
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * jOOQ License and Maintenance Agreement:
 * -----------------------------------------------------------------------------
 * Data Geekery grants the Customer the non-exclusive, timely limited and
 * non-transferable license to install and use the Software under the terms of
 * the jOOQ License and Maintenance Agreement.
 *
 * This library is distributed with a LIMITED WARRANTY. See the jOOQ License
 * and Maintenance Agreement for more details: http://www.jooq.org/eula
 */
package org.jooq.oss

import static java.util.regex.Pattern.*;

import java.io.File
import java.util.ArrayList
import java.util.regex.Pattern
import org.apache.commons.lang3.tuple.ImmutablePair
import org.jooq.SQLDialect
import org.jooq.xtend.Generators

class OSS extends Generators {
    
    def static void main(String[] args) {
        val oss = new OSS();
        
        val workspace = new File("..");
        
        val in1 = new File(workspace, "jOOQ");
        val out1 = new File(workspace, "OSS-jOOQ");
        oss.transform(in1, out1, in1);
        
        val in2 = new File(workspace, "jOOQ-codegen");
        val out2 = new File(workspace, "OSS-jOOQ-codegen");
        oss.transform(in2, out2, in2);
        
        val in3 = new File(workspace, "jOOQ-codegen-maven");
        val out3 = new File(workspace, "OSS-jOOQ-codegen-maven");
        oss.transform(in3, out3, in3);
        
        val in4 = new File(workspace, "jOOQ-meta");
        val out4 = new File(workspace, "OSS-jOOQ-meta");
        oss.transform(in4, out4, in4);
    }

    def transform(File inRoot, File outRoot, File in) {
        val out = new File(outRoot.canonicalPath + "/" + in.canonicalPath.replace(inRoot.canonicalPath, ""));
        
        if (in.directory) {
            val files = in.listFiles[path | 
                   !path.canonicalPath.endsWith(".class") 
                && !path.canonicalPath.endsWith(".project")
                && !path.canonicalPath.endsWith("pom.xml")
                && !path.canonicalPath.contains("\\org\\jooq\\util\\access")
                && !path.canonicalPath.contains("\\org\\jooq\\util\\ase")
                && !path.canonicalPath.contains("\\org\\jooq\\util\\db2")
                && !path.canonicalPath.contains("\\org\\jooq\\util\\ingres")
                && !path.canonicalPath.contains("\\org\\jooq\\util\\oracle")
                && !path.canonicalPath.contains("\\org\\jooq\\util\\sqlserver")
                && !path.canonicalPath.contains("\\org\\jooq\\util\\sybase")
                && !path.canonicalPath.contains("\\target\\")
            ];

            for (file : files) {
                transform(inRoot, outRoot, file);
            }            
        }
        else {
            var content = read(in);

            for (pair : patterns) {
                content = pair.left.matcher(content).replaceAll(pair.right);
            }
            
            write(out, content);
        }
    }
    
    val patterns = new ArrayList<ImmutablePair<Pattern, String>>();
    
    new() {
        
        // Remove sections of commercial code
        patterns.add(new ImmutablePair(compile('''(?s:[ \t]+«quote("/* [com] */")»[ \t]*[\r\n]{0,2}.*?«quote("/* [/com] */")»[ \t]*[\r\n]{0,2})'''), ""));
        patterns.add(new ImmutablePair(compile('''(?s:«quote("/* [com] */")».*?«quote("/* [/com] */")»)'''), ""));
        
        patterns.add(new ImmutablePair(compile('''(?s:[ \t]+«quote("<!-- [com] -->")»[ \t]*[\r\n]{0,2}.*?«quote("<!-- [/com] -->")»[ \t]*[\r\n]{0,2})'''), ""));
        patterns.add(new ImmutablePair(compile('''(?s:«quote("<!-- [com] -->")».*?«quote("<!-- [/com] -->")»)'''), ""));
        
        for (d : SQLDialect::values.filter[d | d.commercial]) {
            
            // Remove commercial dialects from @Support annotations
            patterns.add(new ImmutablePair(compile('''(?s:(\@Support\([^\)]*?),\s*\b«d.name»\b([^\)]*?\)))'''), "$1$2"));
            patterns.add(new ImmutablePair(compile('''(?s:(\@Support\([^\)]*?)\b«d.name»\b,\s*([^\)]*?\)))'''), "$1$2"));
            patterns.add(new ImmutablePair(compile('''(?s:(\@Support\([^\)]*?)\s*\b«d.name»\b\s*([^\)]*?\)))'''), "$1$2"));
            
            // Remove commercial dialects from Arrays.asList() expressions
            patterns.add(new ImmutablePair(compile('''(asList\([^\)]*?),\s*\b«d.name»\b([^\)]*?\))'''), "$1$2"));
            patterns.add(new ImmutablePair(compile('''(asList\([^\)]*?)\b«d.name»\b,\s*([^\)]*?\))'''), "$1$2"));
            patterns.add(new ImmutablePair(compile('''(asList\([^\)]*?)\s*\b«d.name»\b\s*([^\)]*?\))'''), "$1$2"));
            
            // Remove commercial dialects from imports
            patterns.add(new ImmutablePair(compile('''import (static )?org\.jooq\.SQLDialect\.«d.name»;[\r\n]{0,2}'''), ""));
            patterns.add(new ImmutablePair(compile('''import (static )?org\.jooq\.util\.«d.name.toLowerCase»\..*?;[\r\n]{0,2}'''), ""));
        }
    }
}