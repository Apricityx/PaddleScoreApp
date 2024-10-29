# 数据库设计

数据库统一命名采用下划线规则
数据库为以下结构：

## <match_name>.db

> 用于存储比赛数据，比赛事件名字将作为数据库名，例如2024春季比赛.db

### athletes 表 用于存储运动员信息

| 列名   | id  | name    | score | team    |
|------|-----|---------|-------|---------|
| 数据类型 | INT | VARCHAR | FLOAT | VARCHAR |

---

### athletes 表 用于存储运动员信息

| 列名   | id      | name    | score_in_total | team    | group  |
|------|---------|---------|----------------|---------|--------|
| 数据类型 | VARCHAR | VARCHAR | FLOAT          | VARCHAR | STRING |

> 接下来三张表分别记录三次比赛的成绩，分别为：
>
> 1. 6000米长距离赛（青少年3000米）
>
> 2. 200米趴板划水赛（仅限青少年）
>
> 3. 200米竞速赛

### competitions_long_distant 表

| 列名 | id | name | time |



### competitions_prone_paddle 表

### competitions_sprint 表