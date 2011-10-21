//
//  NTIEditableFrame.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/08/22.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniUI/OUIEditableFrame.h"

/**
 * Exists to workaround some bugs manifesting in iOS 5.0beta 6+, specifically
 * OUIEditableFrame breaks badly when asked to handle writing directions. We
 * "fix" this by hardcoding Left-to-Right.
 */
@interface NTIEditableFrame : OUIEditableFrame

@end

//We also replace the base methods until such time as they are
//fixed, because OUIEditableFrame is used in places that we cannot
//be (deep in the inspector, for instance). Pose-as-class would make this
//easier!
