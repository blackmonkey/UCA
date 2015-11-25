//
// Copyright 2011 ESCOZ Inc  - http://escoz.com
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License. You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
// ANY KIND, either express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//


#import "QLabelElement.h"

@implementation QLabelElement {
@private
    UITableViewCellAccessoryType _accessoryType;
}


@synthesize image = _image;
@synthesize value = _value;
@synthesize valueIcon = _valueIcon;
@synthesize accessoryType = _accessoryType;


- (QLabelElement *)initWithTitle:(NSString *)title Value:(id)value {
   self = [super init];
   _title = title;
   _value = value;
    return self;
}

-(void)setImageNamed:(NSString *)name {
    self.image = [UIImage imageNamed:name];
}

- (NSString *)imageNamed {
    return nil;
}


- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    QTableViewCell *cell = (QTableViewCell *) [super getCellForTableView:tableView controller:controller];

    cell.textLabel.text = _title;
    cell.imageView.image = _image;
    cell.selectionStyle = self.sections!= nil || self.controllerAction!=nil ? UITableViewCellSelectionStyleBlue: UITableViewCellSelectionStyleNone;

    if (_valueIcon) {
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:[_value description] forState:UIControlStateNormal];
        [button setImage:_valueIcon forState:UIControlStateNormal];
        [button setTitleColor:cell.detailTextLabel.textColor forState:UIControlStateNormal];
        [button sizeToFit];
        button.userInteractionEnabled = NO;

        cell.accessoryView = button;
    } else {
        cell.detailTextLabel.text = [_value description];
        cell.accessoryType = self.sections!= nil || self.controllerAction!=nil ? (_accessoryType != (int) nil ? _accessoryType : UITableViewCellAccessoryDisclosureIndicator) : UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
    }

    return cell;
}

- (void)selected:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller indexPath:(NSIndexPath *)path {
    [super selected:tableView controller:controller indexPath:path];
}


@end