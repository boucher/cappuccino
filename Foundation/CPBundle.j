/*
 * CPBundle.j
 * Foundation
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CPObject.j"
@import "CPDictionary.j"

@import "CPURLRequest.j"


@implementation CPBundle : CPObject
{
}

+ (id)alloc
{
    return new objj_bundle;
}

+ (CPBundle)bundleWithPath:(CPString)aPath
{
    return objj_getBundleWithPath(aPath);
}

+ (CPBundle)bundleForClass:(Class)aClass
{
    return objj_bundleForClass(aClass);
}

+ (CPBundle)mainBundle
{
    return [CPBundle bundleWithPath:"Info.plist"];
}

- (id)initWithPath:(CPString)aPath
{
    self = [super init];
    
    if (self)
    {
        path = aPath;
        
        objj_setBundleForPath(path, self);
    }
    
    return self;
}

- (Class)classNamed:(CPString)aString
{
    // ???
}

- (CPString)bundlePath
{
    return [path stringByDeletingLastPathComponent];
}

- (CPString)resourcePath
{
    var resourcePath = [self bundlePath];
    
    if (resourcePath.length)
        resourcePath += '/';
        
    return resourcePath + "Resources";
}

- (Class)principalClass
{
    var className = [self objectForInfoDictionaryKey:@"CPPrincipalClass"];
    
    //[self load];
    
    return className ? CPClassFromString(className) : Nil;
}

- (CPDictionary)infoDictionary
{
    return info;
}

- (id)objectForInfoDictionaryKey:(CPString)aKey
{
    return [info objectForKey:aKey];
}

//

- (void)loadWithDelegate:(id)aDelegate
{
    self._delegate = aDelegate;
    self._infoConnection = [CPURLConnection connectionWithRequest:[CPURLRequest requestWithURL:[self bundlePath] + "/Info.plist"] delegate:self];
}

- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)data
{
    if (aConnection === self._infoConnection)
    {
        info = CPPropertyListCreateFromData([CPData dataWithString:data]);

        [CPURLConnection connectionWithRequest:[CPURLRequest requestWithURL:[self bundlePath] + "/" + [self objectForInfoDictionaryKey:"CPBundleExecutable"]] delegate:self];
    }
    else
    {
        objj_decompile([data string], self);
        
        var context = new objj_context();
    
        if ([_delegate respondsToSelector:@selector(bundleDidFinishLoading:)])
            context.didCompleteCallback = function() { [_delegate bundleDidFinishLoading:self]; };
    
        var files = [self objectForInfoDictionaryKey:@"CPBundleReplacedFiles"],
            count = files.length;
            
        while (count--)
            context.pushFragment(fragment_create_file([self bundlePath] + '/' + files[count], new objj_bundle(""), YES, NULL));
        
        context.evaluate();
    }
}

- (void)connectionDidFinishLoading:(CPURLConnection)aConnection
{
}

@end

objj_bundle.prototype.isa = CPBundle;
