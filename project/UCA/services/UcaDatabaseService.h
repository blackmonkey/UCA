/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#define COLUMN_ID @"id"

@interface UcaDatabaseService : UcaService

/**
 * 创建服务相关的数据表。
 * @param tableName 数据表名称
 * @param colInfos 数据表字段信息，格式为：字段1名称，字段1属性，字段2名称，字段2属性，……
 * @return 如果数据表已存在或创建成功则返回YES；否则返回NO。
 */
- (BOOL)createTableIfNeeds:(NSString *)tableName columnInfos:(NSArray *)colInfos;

/**
 * 执行所有的非SELECT语句，包括CREATE，UPDATE，INSERT，ALTER，COMMIT，BEGIN，DETACH，
 * DELETE，DROP，END，EXPLAIN，VACUUM和REPLACE。
 * @param sql 非SELECT语句，需要绑定的参数用“?”占位符；
 * @param arguments 需要绑定的参数；
 * @return 执行成功返回YES；否则返回NO。
 */
- (BOOL)executeUpdate:(NSString*)sql;
- (BOOL)executeUpdate:(NSString*)sql withArguments:(NSArray *)arguments;

/**
 * 执行SELECT语句。
 * @param sql SELECT语句，需要绑定的参数用“?”占位符；
 * @param arguments 需要绑定的参数；
 * @return 执行成功返回FMResultSet实例；否则返回nil。
 */
- (FMResultSet *)executeQuery:(NSString *)sql;
- (FMResultSet *)executeQuery:(NSString *)sql withArguments:(NSArray *)arguments;

/**
 * 获取逗号分隔的?占位符SQL表达式。
 * @param countOfArguments ?占位符的个数
 * @return SQL表达式。
 */
- (NSString *)commaDelimitedArguments:(NSInteger)countOfArguments;

/**
 * 以指定的字段、值，添加数据表记录。
 * @param columns 添加字段。
 * @param values 添加字段的值。
 * @param tableName 数据表名称。
 * @return 如果添加成功则返回有效记录ID；否则返回NOT_SAVED。
 */
- (NSInteger)addRecordWithColumns:(NSArray *)columns
                        andValues:(NSArray *)values
                          toTable:(NSString *)tableName;

/**
 * 更新指定数据表记录的字段、值。
 * @param recordId 数据表记录ID。
 * @param columns 更新字段。
 * @param values 更新字段的值。
 * @param tableName 数据表名称。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
- (BOOL)updateRecord:(NSInteger)recordId
         withColumns:(NSArray *)columns
           andValues:(NSArray *)values
             inTable:(NSString *)tableName;

/**
 * 更新指定数据表记录的字段、值。
 * @param columns 更新字段。
 * @param clause WHERE条件，需要绑定的参数用“?”占位符。
 * @param arguments 更新字段的值和需要绑定的参数；
 * @param tableName 数据表名称。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
- (BOOL)updateRecordsWithColumns:(NSArray *)columns
                           where:(NSString *)clause
                    andArguments:(NSArray *)arguments
                         inTable:(NSString *)tableName;

/**
 * 从数据表中删除记录。
 * @param recordId 数据表记录ID。
 * @param tableName 数据表名称。
 * @return 如果删除成功则返回YES；否则返回NO。
 */
- (BOOL)deleteRecord:(NSInteger)recordId
           fromTable:(NSString *)tableName;

/**
 * 从数据表中删除记录。
 * @param columns 检测字段。
 * @param values 检测字段的值。
 * @param tableName 数据表名称。
 * @return 如果删除成功则返回YES；否则返回NO。
 */
- (BOOL)deleteRecordsWhere:(NSArray *)columns
                    equals:(NSArray *)values
                 fromTable:(NSString *)tableName;

/**
 * 从数据表中删除记录。
 * @param clause WHERE条件，需要绑定的参数用“?”占位符。
 * @param arguments 需要绑定的参数；
 * @param tableName 数据表名称。
 * @return 如果删除成功则返回YES；否则返回NO。
 */
- (BOOL)deleteRecordsWhere:(NSString *)clause
              andArguments:(NSArray *)arguments
                 fromTable:(NSString *)tableName;

/**
 * 获取符合指定条件的记录总数。
 * @param columns 查询字段。
 * @param values 查询字段的值。
 * @param tableName 数据表名称。
 * @return 如果数据表中有符合条件的记录，则返回记录总数；否则返回0。
 */
- (NSUInteger)countOfRecordsWhere:(NSArray *)columns
                           equals:(NSArray *)values
                          inTable:(NSString *)tableName;

/**
 * 获取符合指定条件的记录ID。
 * @param columns 查询字段。
 * @param values 查询字段的值。
 * @param tableName 数据表名称。
 * @return 如果数据表中有符合条件的记录，则返回第一个符合的记录的ID；否则返回NOT_SAVED。
 */
- (NSInteger)recordIdWhere:(NSArray *)columns
                    equals:(NSArray *)values
                   inTable:(NSString *)tableName;

/**
 * 获取符合指定条件的多个记录ID。
 * @param clause WHERE条件，需要绑定的参数用“?”占位符。
 * @param arguments 需要绑定的参数；
 * @param tableName 数据表名称。
 * @return 如果数据表中有符合条件的记录，则返回所有符合的记录的ID；否则返回nil。
 */
- (NSArray *)recordIdsWhere:(NSString *)clause
               andArguments:(NSArray *)arguments
                    inTable:(NSString *)tableName;

@end
