//
//  WAYTheDarkSide.h
//  WAYTheDarkSideDemo
//
//  Created by Raffael Hannemann on 18.11.14.
//  Copyright (c) 2014 We Are Yeah!. All rights reserved.
//  Visit weAreYeah.com or follow @weareYeah for updates.
//
//  Licensed under the BSD License <http://www.opensource.org/licenses/bsd-license>
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
//  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <AppKit/AppKit.h>

/** This class provides several helper methods to handle OS X Yosemite's new Dark Mode. Use this class to determine if the system appearance is currently set up to be in the Dark Mode or not, and if it supports it anyways. Next, specify event handlers per view or window controller (or any other object), which will be performed whenever the user switches the Dark Mode system preferene. */
@interface WAYTheDarkSide : NSObject

/** Returns YES, if the application is running on OS X Yosemite or greater */
+ (BOOL) applicationReadyForTheDarkSide;

/** Returns YES, if OS X is currently set up to use the Dark UI Mode */
+ (BOOL) applicationIsOnTheDarkSide;

/** Sets a block which will be performed whenever the system switches from normal to the dark appearance.
 * @param object			An object as a reference. You can overwrite existing blocks by specifying the same block object again.
 * @param eventHandler		The block that will be performed.
 * @param flag		If YES, the block will be performed immediately, if the system currently already is in the Dark Mode.
 * @discussion				The `object` should be, e.g., your NSWindowController or NSViewController instance.
 */
+ (void) welcomeObject: (id) object withBlock: (void (^)(void)) eventHandler immediately:(BOOL)flag;

/** Sets a block which will be performed whenever the system switches back from the dark to the normal appearance.
 * @param object			An object as a reference. You can overwrite existing blocks by specifying the same block object again.
 * @param eventHandler		The block that will be performed.
 * @param flag		If YES, the block will be performed immediately, if the system currently already is in the normal mode.
 * @discussion				The `object` should be, e.g., your NSWindowController or NSViewController instance.
 */
+ (void) outcastObject: (id) object withBlock: (void (^)(void)) eventHandler immediately:(BOOL)flag;

/** Convenient method to set a general block that will be executed when the user enables the system-wide Dark Mode. Previously defined block(s) will be abandoned.
 * @param eventHandler		The block that will be performed.
 * @param flag		If YES, the block will be performed immediately, if the system currently already is in the Dark Mode.
 * @discussion				Use this method if you plan to use only one event handler globally. This will use the NSApplication delegate as referenced object. */
+ (void) welcomeApplicationWithBlock: (void (^)(void)) eventHandler immediately:(BOOL)flag;

/** Convenient method to set a general block that will be executed when the user disables the system-wide Dark Mode. Previously defined block(s) will be abandoned.
 * @param eventHandler		The block that will be performed.
 * @param flag		If YES, the block will be performed immediately, if the system currently already is in the normal mode.
 * @discussion				Use this method if you plan to use only one event handler globally. This will use the NSApplication delegate as referenced object. */
+ (void) outcastApplicationWithBlock: (void (^)(void)) eventHandler immediately:(BOOL)flag;

@end
