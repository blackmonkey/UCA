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

#import "QuickDialogDataSource.h"

@implementation QuickDialogDataSource

- (id <UITableViewDataSource>)initForTableView:(QuickDialogTableView *)tableView {
    self = [super init];
    if (self) {
       _tableView = tableView;
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tableView.root getSectionForIndex:section].elements.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    QElement * element = [_tableView.root getElementAtIndexPath:indexPath];
    UITableViewCell *cell = [element getCellForTableView:(QuickDialogTableView *) tableView controller:_tableView.controller];

    if (_tableView.styleProvider!=nil){
        [_tableView.styleProvider cell:cell willAppearForElement:element atIndexPath:indexPath];
    }

    /**
     * HARD FIX: when element is nil, cell is nil, the following exception is thrown:
     * Terminating app due to uncaught exception 'NSInternalInconsistencyException',
     * reason: 'UITableView dataSource must return a cell from tableView:cellForRowAtIndexPath:'
     */
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"dummycell"];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_tableView.root numberOfSections];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [_tableView.root getSectionForIndex:section].title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return [_tableView.root getSectionForIndex:section].footer;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    QSection *section = [_tableView.root getSectionForIndex:indexPath.section];
    if (indexPath.row < 0 || indexPath.row >= [section.elements count]) {
        return;
    }

    [section.elements removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    QElement * element = [_tableView.root getElementAtIndexPath:indexPath];
    return element.allowSelectInEditMode && _tableView.editing;
}


/**
 * 以各Section的有效key为index titles。
 */
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (!_tableView.useSectionKeyAsIndexTitle) {
        return nil;
    }

    NSMutableArray *titles = [NSMutableArray array];
    for (QSection *section in _tableView.root.sections) {
        if (![NSString isNullOrEmpty:section.key] && section.useKeyAsIndexTitle) {
            [titles addObject:section.key];
        }
    }
    return titles.count > 0 ? titles : nil;
}

@end