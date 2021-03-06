/*******************************************************************************
 * Copyright (c) 2013, 2019 itemis AG (http://www.itemis.eu) and others.
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 *******************************************************************************/
package org.eclipse.xtext.example.domainmodel.tests

import com.google.inject.Inject
import org.eclipse.xtext.example.domainmodel.domainmodel.DomainModel
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.util.ReplaceRegion
import org.eclipse.xtext.xbase.imports.ImportOrganizer
import org.junit.Test
import org.junit.runner.RunWith

import static org.junit.Assert.*

/**
 * @author Jan Koehnlein - copied and adapted from Xtend
 */
@RunWith(XtextRunner)
@InjectWith(DomainmodelInjectorProvider)
class OrganizeImportsTest {

	@Inject extension ParseHelper<DomainModel>
	@Inject ImportOrganizer importOrganizer

	def protected assertIsOrganizedTo(CharSequence model, CharSequence expected) throws Exception {
		val domainModel = parse(model.toString)
		val changes = importOrganizer.getOrganizedImportChanges(domainModel.eResource as XtextResource)
		val builder = new StringBuilder(model)
		val sortedChanges= changes.sortBy[offset]
		var ReplaceRegion lastChange = null
		for(it: sortedChanges) {
			if(lastChange !== null && lastChange.endOffset > offset)
				fail("Overlapping text edits: " + lastChange + ' and ' +it)
			lastChange = it
		}
		for(it: sortedChanges.reverse)
			builder.replace(offset, offset + length, text)
		assertEquals(expected.toString, builder.toString)
	}

	@Test def testSimple() throws Exception {
		'''
			package foo {
				entity Foo extends java.io.Serializable {}
			}
		'''.assertIsOrganizedTo('''
			import java.io.Serializable
			
			package foo {
				entity Foo extends Serializable {}
			}
		''')
	}

	@Test def testDefaultPackage() throws Exception {
		'''
			entity Foo extends java.io.Serializable {}
		'''.assertIsOrganizedTo('''
			import java.io.Serializable

			entity Foo extends Serializable {}
		''')
	}

	@Test def testDefaultPackageLeadingWhitespace() throws Exception {
		'''
			????
			   	
			entity Foo extends java.io.Serializable {}
		'''.assertIsOrganizedTo('''
			import java.io.Serializable

			entity Foo extends Serializable {}
		''')
	}

	@Test def testDefaultPackageWithJavaDoc() throws Exception {
		'''
			/**
			 * some doc
			 */
			entity Foo extends java.io.Serializable {}
		'''.assertIsOrganizedTo('''
			import java.io.Serializable

			/**
			 * some doc
			 */
			entity Foo extends Serializable {}
		''')
	}

	@Test def testGetOrganizedImportSection_01() throws Exception {
		'''
			import java.lang.String
			import java.util.List

			entity Foo {
			  op test(List<String> s) : void {}
			}
		'''.assertIsOrganizedTo('''
			import java.util.List

			entity Foo {
			  op test(List<String> s) : void {}
			}
		''')
	}

	@Test def testGetOrganizedImportSection_02() throws Exception {
		'''
			import java.lang.String
			import java.util.List
			import java.util.List
			import java.util.List
			import java.lang.Integer

			entity Foo {
			  op test(List<String> s) : void {}
			}
		'''.assertIsOrganizedTo('''
			import java.util.List

			entity Foo {
			  op test(List<String> s) : void {}
			}
		''')
	}

	@Test def testGetOrganizedImportSection_03() throws Exception {
		'''
			import java.util.*

			entity Foo {
			  op test(List<String> s) : void{
			    val x = newArrayList('foo','bar')
			    Collections.sort(x)
			  }
			}
		'''.assertIsOrganizedTo('''
			import java.util.Collections
			import java.util.List

			entity Foo {
			  op test(List<String> s) : void{
			    val x = newArrayList('foo','bar')
			    Collections.sort(x)
			  }
			}
		''')
	}

	@Test def testGetOrganizedImportSection_04() throws Exception {
		'''
			import java.util.*
			import java.io.*

			entity Foo {
			  op test(List<String> s) : void {
			    val x = new ArrayList<Map<StringBuilder,? extends Serializable>>()
			  }
			}
		'''.assertIsOrganizedTo('''
			import java.io.Serializable
			import java.util.ArrayList
			import java.util.List
			import java.util.Map

			entity Foo {
			  op test(List<String> s) : void {
			    val x = new ArrayList<Map<StringBuilder,? extends Serializable>>()
			  }
			}
		''')
	}

	@Test def testInnerClasses_01() throws Exception {
		'''
			entity Foo {
			  op test(org.eclipse.emf.ecore.resource.Resource$Factory a, org.eclipse.emf.ecore.resource.Resource$Factory$Registry b) : void {}
			}
		'''.assertIsOrganizedTo('''
			import org.eclipse.emf.ecore.resource.Resource

			entity Foo {
			  op test(Resource.Factory a, Resource.Factory.Registry b) : void {}
			}
		''')
	}

	@Test def testInnerClasses_02() throws Exception {
		'''
			import org.eclipse.emf.ecore.resource.Resource
			import org.eclipse.emf.ecore.EPackage

			entity Foo {
			  op test() : void {
			    val x = Resource$Factory$Registry::INSTANCE
			    val y = EPackage$Registry::INSTANCE
			  }
			}
		'''.assertIsOrganizedTo('''
			import org.eclipse.emf.ecore.EPackage
			import org.eclipse.emf.ecore.resource.Resource

			entity Foo {
			  op test() : void {
			    val x = Resource.Factory.Registry::INSTANCE
			    val y = EPackage.Registry::INSTANCE
			  }
			}
		''')
	}

	@Test def testInnerClasses_03() throws Exception {
		'''
			entity Foo {
			  op test() : boolean {
				 typeof(org.eclipse.emf.ecore.resource.Resource$Factory) == typeof(org.eclipse.emf.ecore.resource.Resource$Factory$Registry)
			  }
			}
		'''.assertIsOrganizedTo('''
			import org.eclipse.emf.ecore.resource.Resource

			entity Foo {
			  op test() : boolean {
				 typeof(Resource.Factory) == typeof(Resource.Factory.Registry)
			  }
			}
		''')
	}

	@Test def testInnerClasses_04() throws Exception {
		'''
			import org.eclipse.emf.ecore.resource.Resource
			import org.eclipse.emf.ecore.EPackage

			entity Foo {
			  op test() : void {
			    typeof(Resource$Factory$Registry) == typeof(EPackage$Registry)
			  }
			}
		'''.assertIsOrganizedTo('''
			import org.eclipse.emf.ecore.EPackage
			import org.eclipse.emf.ecore.resource.Resource

			entity Foo {
			  op test() : void {
			    typeof(Resource.Factory.Registry) == typeof(EPackage.Registry)
			  }
			}
		''')
	}

	@Test def testInnerClasses_05() throws Exception {
		'''
			import org.eclipse.emf.ecore.resource.Resource$Factory$Registry

			entity Foo {
			  op test() : void {
			    typeof(Registry)
			  }
			}
		'''.assertIsOrganizedTo('''
			import org.eclipse.emf.ecore.resource.Resource.Factory.Registry

			entity Foo {
			  op test() : void {
			    typeof(Registry)
			  }
			}
		''')
	}

	@Test def testNameClashSameFileWins_1() throws Exception {
		'''
			package foo {
				entity Foo {
					x : java.lang.String
				}

				entity String {}
			}
		'''.assertIsOrganizedTo('''
			package foo {
				entity Foo {
					x : java.lang.String
				}

				entity String {}
			}
		''')
	}

	@Test def testNameClashSameFileWins() throws Exception {
		'''
			package foo {
				entity Foo extends java.io.Serializable{}

				entity Serializable {}
			}
		'''.assertIsOrganizedTo('''
			package foo {
				entity Foo extends java.io.Serializable{}

				entity Serializable {}
			}
		''')
	}

	@Test def testNameClashOrder_01() throws Exception {
		'''
			entity Foo {
			  op test(java.util.List<String> s) : java.awt.List {
			    return null
			  }
			}
		'''.assertIsOrganizedTo('''
			import java.awt.List

			entity Foo {
			  op test(java.util.List<String> s) : List {
			    return null
			  }
			}
		''')
	}

	@Test def testNameClashOrder_02() throws Exception {
		'''
			entity Foo {
			  op test(java.awt.List<String> s) : java.util.List  {
			    return null
			  }
			}
		'''.assertIsOrganizedTo('''
			import java.util.List

			entity Foo {
			  op test(java.awt.List<String> s) : List  {
			    return null
			  }
			}
		''')
	}

	@Test def testNameClashMoreCommon() throws Exception {
		'''
			entity Foo {
			  op test(java.awt.List s) : java.util.List<String> {
			  	new java.awt.List()
			    return null
			  }
			}
		'''.assertIsOrganizedTo('''
			import java.awt.List

			entity Foo {
			  op test(List s) : java.util.List<String> {
			  	new List()
			    return null
			  }
			}
		''')
	}

	@Test def testNameClashInnerClasses() throws Exception {
		'''
			import org.eclipse.xtext.xbase.XbasePackage
			import org.eclipse.xtext.xbase.annotations.xAnnotations.XAnnotationsPackage

			entity Foo {
			  op test(XbasePackage$Literals x, XAnnotationsPackage$Literals y) : void {
			  }
			}
		'''.assertIsOrganizedTo('''
			import org.eclipse.xtext.xbase.XbasePackage
			import org.eclipse.xtext.xbase.annotations.xAnnotations.XAnnotationsPackage

			entity Foo {
			  op test(XbasePackage.Literals x, XAnnotationsPackage.Literals y) : void {
			  }
			}
		''')
	}

	@Test def testNameClashInnerClassesWithPreference() throws Exception {
		'''
			import org.eclipse.xtext.xbase.XbasePackage$Literals
			import org.eclipse.xtext.xbase.annotations.xAnnotations.XAnnotationsPackage

			entity Foo {
			  op test(Literals x, XAnnotationsPackage$Literals y) : void {
			  }
			}
		'''.assertIsOrganizedTo('''
			import org.eclipse.xtext.xbase.XbasePackage.Literals
			import org.eclipse.xtext.xbase.annotations.xAnnotations.XAnnotationsPackage

			entity Foo {
			  op test(Literals x, XAnnotationsPackage.Literals y) : void {
			  }
			}
		''')
	}

	@Test def testStaticImport_01() throws Exception {
		'''
			import static java.util.Collections.*
			entity Foo {
			  op test(java.util.List<String> s) : void {
			  	shuffle(s)
			  }
			}
		'''.assertIsOrganizedTo('''
			import java.util.List
			
			import static java.util.Collections.*

			entity Foo {
			  op test(List<String> s) : void {
			  	shuffle(s)
			  }
			}
		''')
	}

	@Test def testStaticImport_02() throws Exception {
		'''
			import static extension java.util.Collections.*
			entity Foo {
			  op test(java.util.List<String> s) : void {
			    s.shuffle
			  }
			}
		'''.assertIsOrganizedTo('''
			import java.util.List
			
			import static extension java.util.Collections.*

			entity Foo {
			  op test(List<String> s) : void {
			    s.shuffle
			  }
			}
		''')
	}

	@Test def testImplicitExtensions() throws Exception {
		'''
			entity Foo {
			  op test(java.util.List<String> s) : void {
			    s.head
			  }
			}
		'''.assertIsOrganizedTo('''
			import java.util.List

			entity Foo {
			  op test(List<String> s) : void {
			    s.head
			  }
			}
		''')
	}

	@Test def testStaticExtensions() throws Exception {
		'''
			import static extension java.util.Collections.*
			entity Foo {
			  op test() : void {
			    typeof(java.util.Collections).singleton
			  }
			}
		'''.assertIsOrganizedTo('''
			import java.util.Collections

			import static extension java.util.Collections.*

			entity Foo {
			  op test() : void {
			    typeof(Collections).singleton
			  }
			}
		''')
	}

	@Test def testInnerClassImport_01() throws Exception {
		'''
			import java.util.Map$Entry
			
			package foo.bar {
				entity Foo {
				  op test() : Entry {
				    return null
				  }
				}
			}
		'''.assertIsOrganizedTo('''
			import java.util.Map.Entry

			package foo.bar {
				entity Foo {
				  op test() : Entry {
				    return null
				  }
				}
			}
		''')
	}

	@Test def testInnerClassImport_02() throws Exception {
		'''
			import java.util.Map
			
			package foo.bar {
				entity Foo {
				  op test() : Map$Entry {
				    return null
				  }
				}
			}
		'''.assertIsOrganizedTo('''
			import java.util.Map

			package foo.bar {
				entity Foo {
				  op test() : Map.Entry {
				    return null
				  }
				}
			}
		''')
	}

	@Test def testInnerClassImport_03() throws Exception {
		'''
			import java.util.Map$Entry

			package foo.bar {
				entity Foo {
				  op test() : Map$Entry {
				    return null
				  }
				}
			}
		'''.assertIsOrganizedTo('''
			import java.util.Map

			package foo.bar {
				entity Foo {
				  op test() : Map.Entry {
				    return null
				  }
				}
			}
		''')
	}

	@Test def testInnerClassImport_04() throws Exception {
		'''
			import org.eclipse.emf.ecore.resource.Resource

			package foo.bar {
				entity Foo {
				  op test() : Resource$Factory$Descriptor {
				    return null
				  }
				}
			}
		'''.assertIsOrganizedTo('''
			import org.eclipse.emf.ecore.resource.Resource

			package foo.bar {
				entity Foo {
				  op test() : Resource.Factory.Descriptor {
				    return null
				  }
				}
			}
		''')
	}

	@Test def testInnerClassImport_05() throws Exception {
		'''
			import org.eclipse.emf.ecore.resource.Resource$Factory$Descriptor

			package foo.bar {
				entity Foo {
				  op test() : Resource$Factory$Descriptor {
				    return null
				  }
				}
			}
		'''.assertIsOrganizedTo('''
			import org.eclipse.emf.ecore.resource.Resource

			package foo.bar {
				entity Foo {
				  op test() : Resource.Factory.Descriptor {
				    return null
				  }
				}
			}
		''')
	}

	@Test def testInnerClassImport_06() throws Exception {
		'''
			import org.eclipse.emf.ecore.resource.Resource$Factory$Descriptor

			package foo.bar {
				entity Foo {
				  op test() : Descriptor {
				    return null
				  }
				}
			}
		'''.assertIsOrganizedTo('''
			import org.eclipse.emf.ecore.resource.Resource.Factory.Descriptor

			package foo.bar {
				entity Foo {
				  op test() : Descriptor {
				    return null
				  }
				}
			}
		''')
	}

	@Test def testFunctionTypes_afterResolve() throws Exception {
		'''
			import java.util.Map$Entry

			package foo.bar {
				entity Foo {
				  op test() : (Entry)=>void {
				    return null
				  }
				}
			}
		'''.assertIsOrganizedTo('''
			import java.util.Map.Entry

			package foo.bar {
				entity Foo {
				  op test() : (Entry)=>void {
				    return null
				  }
				}
			}
		''')
	}

	@Test def testImport_PairOf() throws Exception {
		'''
			import static org.eclipse.xtext.xbase.lib.Pair.*

			package foo.bar {
				entity Foo {
				  op test() : Object {
				    return of('', '')
				  }
				}
			}
		'''.assertIsOrganizedTo('''
			import static org.eclipse.xtext.xbase.lib.Pair.*

			package foo.bar {
				entity Foo {
				  op test() : Object {
				    return of('', '')
				  }
				}
			}
		''')
	}

	@Test def testArrayType() throws Exception {
		'''
			import java.io.Serializable

			package foo.bar {
				entity Foo {
				  op test() : Serializable[][] {
				    return null
				  }
				}
			}
		'''.assertIsOrganizedTo('''
			import java.io.Serializable

			package foo.bar {
				entity Foo {
				  op test() : Serializable[][] {
				    return null
				  }
				}
			}
		''')
	}

	@Test def testClassWithSameName() throws Exception {
		'''
			package foo.bar {
				entity Serializable {
				  clazz : Class<? extends java.io.Serializable>
				}
			}
		'''.assertIsOrganizedTo('''
			package foo.bar {
				entity Serializable {
				  clazz : Class<? extends java.io.Serializable>
				}
			}
		''')
	}

	@Test def testJavaDoc() throws Exception {
		'''
			/**
			 * {@link java.util.List}
			 */
			entity Foo {}
		'''.assertIsOrganizedTo('''
			import java.util.List
			
			/**
			 * {@link List}
			 */
			entity Foo {}
		''')
	}

	@Test def testLocalNameClash() throws Exception {
		'''
			package foo {
				entity Referrer {
					foo0: foo.bar.Foo
					foo1: foo.baz.Foo
				}
				package bar {
					entity Foo {
						self: Foo
					}
				}
				package baz {
					entity Foo {
						self: Foo
					}
				}
			}
		'''.assertIsOrganizedTo('''
			package foo {
				entity Referrer {
					foo0: foo.bar.Foo
					foo1: foo.baz.Foo
				}
				package bar {
					entity Foo {
						self: Foo
					}
				}
				package baz {
					entity Foo {
						self: Foo
					}
				}
			}
		''')
	}

	@Test def testSamePackage() throws Exception {
		'''
			package bar {
				entity Foo {}
				entity Bar {
					foo: bar.Foo
				}
			}
		'''.assertIsOrganizedTo('''
			package bar {
				entity Foo {}
				entity Bar {
					foo: Foo
				}
			}
		''')
	}

	@Test def testSuperPackage() throws Exception {
		'''
			package bar {
				entity Foo {}
				package baz {
					entity Bar {
						foo: bar.Foo
					}
				}
			}
		'''.assertIsOrganizedTo('''
			import bar.Foo
			
			package bar {
				entity Foo {}
				package baz {
					entity Bar {
						foo: Foo
					}
				}
			}
		''')
	}

	@Test def testSubPackage() throws Exception {
		'''
			import bar.Foo
			
			package bar {
				entity Foo {
					bar : bar.baz.Bar
				}
				package baz {
					entity Bar {}
				}
			}
		'''.assertIsOrganizedTo('''
			import bar.baz.Bar
			
			package bar {
				entity Foo {
					bar : Bar
				}
				package baz {
					entity Bar {}
				}
			}
		''')
	}
}