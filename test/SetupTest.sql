/*-----------------------------------------------------------------------------
 * SetupTest.sql
 *   Creates a user named "CX_ORACLE" and populates its schema with the tables
 * and packages necessary for performing the test suite. It also creates a user
 * named "CX_ORACLE_PROXY" for testing proxying.
 *---------------------------------------------------------------------------*/

whenever sqlerror exit failure

-- drop existing users, if present
begin
  for r in
      ( select username
        from dba_users
        where username in ('CX_ORACLE', 'CX_ORACLE_PROXY')
      ) loop
    execute immediate 'drop user ' || r.username || ' cascade';
  end loop;
end;
/

alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
alter session set nls_numeric_characters='.,';

create user cx_Oracle identified by dev
quota unlimited on users
default tablespace users;

create user cx_Oracle_proxy identified by dev;
alter user cx_Oracle_proxy grant connect through cx_Oracle;

grant create session to cx_Oracle_proxy;

grant
  create session,
  create table,
  create procedure,
  create type,
  select any dictionary,
  change notification
to cx_Oracle;

grant execute on dbms_aqadm to cx_Oracle;

-- create types
create type cx_Oracle.udt_SubObject as object (
  SubNumberValue        number,
  SubStringValue        varchar2(60)
);
/

create type cx_Oracle.udt_ObjectArray as varray(10) of cx_Oracle.udt_SubObject;
/

create type cx_Oracle.udt_Object as object (
  NumberValue           number,
  StringValue           varchar2(60),
  FixedCharValue        char(10),
  IntValue              integer,
  SmallIntValue         smallint,
  FloatValue            float,
  DateValue             date,
  TimestampValue        timestamp,
  SubObjectValue        cx_Oracle.udt_SubObject,
  SubObjectArray        cx_Oracle.udt_ObjectArray
);
/

create type cx_Oracle.udt_Array as varray(10) of number;
/

create or replace type cx_Oracle.udt_Building as object (
    BuildingId number(9),
    NumFloors number(3),
    Description varchar2(60),
    DateBuilt date
);
/

-- create tables
create table cx_Oracle.TestNumbers (
  IntCol                number(9) not null,
  NumberCol             number(9, 2) not null,
  FloatCol              float not null,
  UnconstrainedCol      number not null,
  NullableCol           number(38)
);

create table cx_Oracle.TestStrings (
  IntCol                number(9) not null,
  StringCol             varchar2(20) not null,
  RawCol                raw(30) not null,
  FixedCharCol          char(40) not null,
  NullableCol           varchar2(50)
);

create table cx_Oracle.TestUnicodes (
  IntCol                number(9) not null,
  UnicodeCol            nvarchar2(20) not null,
  FixedUnicodeCol       nchar(40) not null,
  NullableCol           nvarchar2(50)
);

create table cx_Oracle.TestDates (
  IntCol                number(9) not null,
  DateCol               date not null,
  NullableCol           date
);

create table cx_Oracle.TestCLOBs (
  IntCol                number(9) not null,
  CLOBCol               clob not null
);

create table cx_Oracle.TestNCLOBs (
  IntCol                number(9) not null,
  NCLOBCol              nclob not null
);

create table cx_Oracle.TestBLOBs (
  IntCol                number(9) not null,
  BLOBCol               blob not null
);

create table cx_Oracle.TestXML (
  IntCol                number(9) not null,
  XMLCol                xmltype not null
);

create table cx_Oracle.TestLongs (
  IntCol                number(9) not null,
  LongCol               long not null
);

create table cx_Oracle.TestLongRaws (
  IntCol                number(9) not null,
  LongRawCol            long raw not null
);

create table cx_Oracle.TestTempTable (
  IntCol                number(9) not null,
  StringCol             varchar2(400),
  constraint TestTempTable_pk primary key (IntCol)
);

create table cx_Oracle.TestArrayDML (
  IntCol                number(9) not null,
  StringCol             varchar2(100),
  IntCol2               number(3),
  constraint TestArrayDML_pk primary key (IntCol)
);

create table cx_Oracle.TestObjects (
  IntCol                number(9) not null,
  ObjectCol             cx_Oracle.udt_Object,
  ArrayCol              cx_Oracle.udt_Array
);

create table cx_Oracle.TestTimestamps (
  IntCol                number(9) not null,
  TimestampCol          timestamp not null,
  NullableCol           timestamp
);

create table cx_Oracle.TestIntervals (
  IntCol                number(9) not null,
  IntervalCol           interval day to second not null,
  NullableCol           interval day to second
);

create table cx_Oracle.TestUniversalRowids (
  IntCol                number(9) not null,
  StringCol             varchar2(250) not null,
  DateCol               date not null,
  constraint TestUniversalRowids_pk primary key (IntCol, StringCol, DateCol)
) organization index;

create table cx_Oracle.TestBuildings (
    BuildingId number(9) not null,
    BuildingObj cx_Oracle.udt_Building not null
);

-- populate tables
begin
  for i in 1..10 loop
    insert into cx_Oracle.TestNumbers
    values (i, i + i * 0.25, i + i * .75, i * i * i + i *.5,
        decode(mod(i, 2), 0, null, power(143, i)));
  end loop;
end;
/

declare

  t_RawValue            raw(30);

  function ConvertHexDigit(a_Value number) return varchar2 is
  begin
    if a_Value between 0 and 9 then
      return to_char(a_Value);
    end if;
    return chr(ascii('A') + a_Value - 10);
  end;

  function ConvertToHex(a_Value varchar2) return varchar2 is
    t_HexValue          varchar2(60);
    t_Digit             number;
  begin
    for i in 1..length(a_Value) loop
      t_Digit := ascii(substr(a_Value, i, 1));
      t_HexValue := t_HexValue ||
          ConvertHexDigit(trunc(t_Digit / 16)) ||
          ConvertHexDigit(mod(t_Digit, 16));
    end loop;
    return t_HexValue;
  end;

begin
  for i in 1..10 loop
    t_RawValue := hextoraw(ConvertToHex('Raw ' || to_char(i)));
    insert into cx_Oracle.TestStrings
    values (i, 'String ' || to_char(i), t_RawValue,
        'Fixed Char ' || to_char(i),
        decode(mod(i, 2), 0, null, 'Nullable ' || to_char(i)));
  end loop;
end;
/

begin
  for i in 1..10 loop
    insert into cx_Oracle.TestUnicodes
    values (i, 'Unicode ' || unistr('\3042') || ' ' || to_char(i),
        'Fixed Unicode ' || to_char(i),
        decode(mod(i, 2), 0, null, unistr('Nullable ') || to_char(i)));
  end loop;
end;
/

begin
  for i in 1..10 loop
    insert into cx_Oracle.TestDates
    values (i, to_date(20021209, 'YYYYMMDD') + i + i * .1,
        decode(mod(i, 2), 0, null,
        to_date(20021209, 'YYYYMMDD') + i + i + i * .15));
  end loop;
end;
/

begin
  for i in 1..100 loop
    insert into cx_Oracle.TestXML
    values (i, '<?xml version="1.0"?><records>' ||
        dbms_random.string('x', 1024) || '</records>');
  end loop;
end;
/

begin
  for i in 1..10 loop
    insert into cx_Oracle.TestTimestamps
    values (i, to_timestamp('20021209', 'YYYYMMDD') +
            to_dsinterval(to_char(i) || ' 00:00:' || to_char(i * 2) || '.' ||
                    to_char(i * 50)),
        decode(mod(i, 2), 0, to_timestamp(null, 'YYYYMMDD'),
        to_timestamp('20021209', 'YYYYMMDD') +
            to_dsinterval(to_char(i + 1) || ' 00:00:' ||
                    to_char(i * 3) || '.' || to_char(i * 125))));
  end loop;
end;
/

begin
  for i in 1..10 loop
    insert into cx_Oracle.TestIntervals
    values (i, to_dsinterval(to_char(i) || ' ' || to_char(i) || ':' ||
            to_char(i * 2) || ':' || to_char(i * 3)),
            decode(mod(i, 2), 0, to_dsinterval(null),
            to_dsinterval(to_char(i + 5) || ' ' || to_char(i + 2) || ':' ||
            to_char(i * 2 + 5) || ':' || to_char(i * 3 + 5))));
  end loop;
end;
/

insert into cx_Oracle.TestObjects values (1,
    cx_Oracle.udt_Object(1, 'First row', 'First', 2, 5, 12.5,
        to_date(20070306, 'YYYYMMDD'),
        to_timestamp('20080912 16:40:00', 'YYYYMMDD HH24:MI:SS'),
        cx_Oracle.udt_SubObject(11, 'Sub object 1'),
        cx_Oracle.udt_ObjectArray(
                cx_Oracle.udt_SubObject(5, 'first element'),
                cx_Oracle.udt_SubObject(6, 'second element'))),
    cx_Oracle.udt_Array(5, 10, null, 20));

insert into cx_Oracle.TestObjects values (2, null,
    cx_Oracle.udt_Array(3, null, 9, 12, 15));

insert into cx_Oracle.TestObjects values (3,
    cx_Oracle.udt_Object(3, 'Third row', 'Third', 4, 10, 43.25,
        to_date(20070621, 'YYYYMMDD'),
        to_timestamp('20071213 07:30:45', 'YYYYMMDD HH24:MI:SS'),
        cx_Oracle.udt_SubObject(13, 'Sub object 3'),
        cx_Oracle.udt_ObjectArray(
                cx_Oracle.udt_SubObject(10, 'element #1'),
                cx_Oracle.udt_SubObject(20, 'element #2'),
                cx_Oracle.udt_SubObject(30, 'element #3'),
                cx_Oracle.udt_SubObject(40, 'element #4'))), null);

commit;

-- create procedures for testing callproc()
create procedure cx_Oracle.proc_Test (
  a_InValue             varchar2,
  a_InOutValue          in out number,
  a_OutValue            out number
) as
begin
  a_InOutValue := a_InOutValue * length(a_InValue);
  a_OutValue := length(a_InValue);
end;
/

create procedure cx_Oracle.proc_TestNoArgs as
begin
  null;
end;
/

-- create functions for testing callfunc()
create function cx_Oracle.func_Test (
  a_String              varchar2,
  a_ExtraAmount         number
) return number as
begin
  return length(a_String) + a_ExtraAmount;
end;
/

create function cx_Oracle.func_TestNoArgs
return number as
begin
  return 712;
end;
/

-- create packages
create or replace package cx_Oracle.pkg_TestStringArrays as

  type udt_StringList is table of varchar2(100) index by binary_integer;

  function TestInArrays (
    a_StartingLength    number,
    a_Array             udt_StringList
  ) return number;

  procedure TestInOutArrays (
    a_NumElems          number,
    a_Array             in out nocopy udt_StringList
  );

  procedure TestOutArrays (
    a_NumElems          number,
    a_Array             out nocopy udt_StringList
  );

  procedure TestIndexBy (
    a_Array             out nocopy udt_StringList
  );

end;
/

create or replace package body cx_Oracle.pkg_TestStringArrays as

  function TestInArrays (
    a_StartingLength    number,
    a_Array             udt_StringList
  ) return number is
    t_Length            number;
  begin
    t_Length := a_StartingLength;
    for i in 1..a_Array.count loop
      t_Length := t_Length + length(a_Array(i));
    end loop;
    return t_Length;
  end;

  procedure TestInOutArrays (
    a_NumElems          number,
    a_Array             in out udt_StringList
  ) is
  begin
    for i in 1..a_NumElems loop
      a_Array(i) := 'Converted element # ' ||
          to_char(i) || ' originally had length ' ||
          to_char(length(a_Array(i)));
    end loop;
  end;

  procedure TestOutArrays (
    a_NumElems          number,
    a_Array             out udt_StringList
  ) is
  begin
    for i in 1..a_NumElems loop
      a_Array(i) := 'Test out element # ' || to_char(i);
    end loop;
  end;

  procedure TestIndexBy (
    a_Array             out nocopy udt_StringList
  ) is
  begin
    a_Array(-1048576) := 'First element';
    a_Array(-576) := 'Second element';
    a_Array(284) := 'Third element';
    a_Array(8388608) := 'Fourth element';
  end;

end;
/

create or replace package cx_Oracle.pkg_TestUnicodeArrays as

  type udt_UnicodeList is table of nvarchar2(100) index by binary_integer;

  function TestInArrays (
    a_StartingLength    number,
    a_Array             udt_UnicodeList
  ) return number;

  procedure TestInOutArrays (
    a_NumElems          number,
    a_Array             in out nocopy udt_UnicodeList
  );

  procedure TestOutArrays (
    a_NumElems          number,
    a_Array             out nocopy udt_UnicodeList
  );

end;
/

create or replace package body cx_Oracle.pkg_TestUnicodeArrays as

  function TestInArrays (
    a_StartingLength    number,
    a_Array             udt_UnicodeList
  ) return number is
    t_Length            number;
  begin
    t_Length := a_StartingLength;
    for i in 1..a_Array.count loop
      t_Length := t_Length + length(a_Array(i));
    end loop;
    return t_Length;
  end;

  procedure TestInOutArrays (
    a_NumElems          number,
    a_Array             in out udt_UnicodeList
  ) is
  begin
    for i in 1..a_NumElems loop
      a_Array(i) := unistr('Converted element ' || unistr('\3042') ||
          ' # ') || to_char(i) || ' originally had length ' ||
          to_char(length(a_Array(i)));
    end loop;
  end;

  procedure TestOutArrays (
    a_NumElems          number,
    a_Array             out udt_UnicodeList
  ) is
  begin
    for i in 1..a_NumElems loop
      a_Array(i) := unistr('Test out element ') || unistr('\3042') || ' # ' ||
          to_char(i);
    end loop;
  end;

end;
/

create or replace package cx_Oracle.pkg_TestNumberArrays as

  type udt_NumberList is table of number index by binary_integer;

  function TestInArrays (
    a_StartingValue     number,
    a_Array             udt_NumberList
  ) return number;

  procedure TestInOutArrays (
    a_NumElems          number,
    a_Array             in out nocopy udt_NumberList
  );

  procedure TestOutArrays (
    a_NumElems          number,
    a_Array             out nocopy udt_NumberList
  );

end;
/

create or replace package body cx_Oracle.pkg_TestNumberArrays as

  function TestInArrays (
    a_StartingValue     number,
    a_Array             udt_NumberList
  ) return number is
    t_Value             number;
  begin
    t_Value := a_StartingValue;
    for i in 1..a_Array.count loop
      t_Value := t_Value + a_Array(i);
    end loop;
    return t_Value;
  end;

  procedure TestInOutArrays (
    a_NumElems          number,
    a_Array             in out udt_NumberList
  ) is
  begin
    for i in 1..a_NumElems loop
      a_Array(i) := a_Array(i) * 10;
    end loop;
  end;

  procedure TestOutArrays (
    a_NumElems          number,
    a_Array             out udt_NumberList
  ) is
  begin
    for i in 1..a_NumElems loop
      a_Array(i) := i * 100;
    end loop;
  end;

end;
/

create or replace package cx_Oracle.pkg_TestDateArrays as

  type udt_DateList is table of date index by binary_integer;

  function TestInArrays (
    a_StartingValue     number,
    a_BaseDate          date,
    a_Array             udt_DateList
  ) return number;

  procedure TestInOutArrays (
    a_NumElems          number,
    a_Array             in out nocopy udt_DateList
  );

  procedure TestOutArrays (
    a_NumElems          number,
    a_Array             out nocopy udt_DateList
  );

end;
/

create or replace package body cx_Oracle.pkg_TestDateArrays as

  function TestInArrays (
    a_StartingValue     number,
    a_BaseDate          date,
    a_Array             udt_DateList
  ) return number is
    t_Value             number;
  begin
    t_Value := a_StartingValue;
    for i in 1..a_Array.count loop
      t_Value := t_Value + a_Array(i) - a_BaseDate;
    end loop;
    return t_Value;
  end;

  procedure TestInOutArrays (
    a_NumElems          number,
    a_Array             in out udt_DateList
  ) is
  begin
    for i in 1..a_NumElems loop
      a_Array(i) := a_Array(i) + 7;
    end loop;
  end;

  procedure TestOutArrays (
    a_NumElems          number,
    a_Array             out udt_DateList
  ) is
  begin
    for i in 1..a_NumElems loop
      a_Array(i) := to_date(20021212, 'YYYYMMDD') + i * 1.2;
    end loop;
  end;

end;
/

create or replace package cx_Oracle.pkg_TestOutCursors as

  type udt_RefCursor is ref cursor;

  procedure TestOutCursor (
    a_MaxIntValue       number,
    a_Cursor            out udt_RefCursor
  );

end;
/

create or replace package body cx_Oracle.pkg_TestOutCursors as

  procedure TestOutCursor (
    a_MaxIntValue       number,
    a_Cursor            out udt_RefCursor
  ) is
  begin
    open a_Cursor for
      select
        IntCol,
        StringCol
      from TestStrings
      where IntCol <= a_MaxIntValue
      order by IntCol;
  end;

end;
/

create or replace package cx_Oracle.pkg_TestBooleans as

    type udt_BooleanList is table of boolean index by binary_integer;

    function GetStringRep (
        a_Value             boolean
    ) return varchar2;

    function IsLessThan10 (
        a_Value             number
    ) return boolean;

    function TestInArrays (
        a_Value             udt_BooleanList
    ) return number;

    procedure TestOutArrays (
        a_NumElements       number,
        a_Value             out nocopy udt_BooleanList
    );

end;
/

create or replace package body cx_Oracle.pkg_TestBooleans as

    function GetStringRep (
        a_Value             boolean
    ) return varchar2 is
    begin
        if a_Value is null then
            return 'NULL';
        elsif a_Value then
            return 'TRUE';
        end if;
        return 'FALSE';
    end;

    function IsLessThan10 (
        a_Value             number
    ) return boolean is
    begin
        return a_Value < 10;
    end;

    function TestInArrays (
        a_Value             udt_BooleanList
    ) return number is
        t_Result            pls_integer;
    begin
        t_Result := 0;
        for i in 1..a_Value.count loop
            if a_Value(i) then
                t_Result := t_Result + 1;
            end if;
        end loop;
        return t_Result;
    end;

    procedure TestOutArrays (
        a_NumElements       number,
        a_Value             out nocopy udt_BooleanList
    ) is
    begin
        for i in 1..a_NumElements loop
            a_Value(i) := (mod(i, 2) = 1);
        end loop;
    end;

end;
/

create or replace package cx_Oracle.pkg_TestBindObject as

    function GetStringRep (
        a_Object        udt_Object
    ) return varchar2;

end;
/

create or replace package body cx_Oracle.pkg_TestBindObject as

    function GetStringRep (
        a_Object        udt_SubObject
    ) return varchar2 is
    begin
        if a_Object is null then
            return 'null';
        end if;
        return 'udt_SubObject(' ||
                nvl(to_char(a_Object.SubNumberValue), 'null') || ', ' ||
                case when a_Object.SubStringValue is null then 'null'
                else '''' || a_Object.SubStringValue || '''' end || ')';
    end;

    function GetStringRep (
        a_Array         udt_ObjectArray
    ) return varchar2 is
        t_StringRep     varchar2(4000);
    begin
        if a_Array is null then
            return 'null';
        end if;
        t_StringRep := 'udt_ObjectArray(';
        for i in 1..a_Array.count loop
            if i > 1 then
                t_StringRep := t_StringRep || ', ';
            end if;
            t_StringRep := t_StringRep || GetStringRep(a_Array(i));
        end loop;
        return t_StringRep || ')';
    end;

    function GetStringRep (
        a_Object        udt_Object
    ) return varchar2 is
    begin
        if a_Object is null then
            return 'null';
        end if;
        return 'udt_Object(' ||
                nvl(to_char(a_Object.NumberValue), 'null') || ', ' ||
                case when a_Object.StringValue is null then 'null'
                else '''' || a_Object.StringValue || '''' end || ', ' ||
                case when a_Object.FixedCharValue is null then 'null'
                else '''' || a_Object.FixedCharValue || '''' end || ', ' ||
                case when a_Object.DateValue is null then 'null'
                else 'to_date(''' ||
                        to_char(a_Object.DateValue, 'YYYY-MM-DD') ||
                        ''', ''YYYY-MM-DD'')' end || ', ' ||
                case when a_Object.TimestampValue is null then 'null'
                else 'to_timestamp(''' || to_char(a_Object.TimestampValue,
                        'YYYY-MM-DD HH24:MI:SS') ||
                        ''', ''YYYY-MM-DD HH24:MI:SS'')' end || ', ' ||
                GetStringRep(a_Object.SubObjectValue) || ', ' ||
                GetStringRep(a_Object.SubObjectArray) || ')';
    end;

end;
/

create or replace package cx_Oracle.pkg_TestRecords as

    type udt_Record is record (
        NumberValue         number,
        StringValue         varchar2(30),
        DateValue           date,
        TimestampValue      timestamp,
        BooleanValue        boolean
    );

    type udt_RecordArray is table of udt_Record index by binary_integer;

    function GetStringRep (
        a_Value             udt_Record
    ) return varchar2;

    procedure TestOut (
        a_Value             out nocopy udt_Record
    );

    function TestInArrays (
        a_Value             udt_RecordArray
    ) return varchar2;

end;
/

create or replace package body cx_Oracle.pkg_TestRecords as

    function GetStringRep (
        a_Value             udt_Record
    ) return varchar2 is
    begin
        return 'udt_Record(' ||
                nvl(to_char(a_Value.NumberValue), 'null') || ', ' ||
                case when a_Value.StringValue is null then 'null'
                else '''' || a_Value.StringValue || '''' end || ', ' ||
                case when a_Value.DateValue is null then 'null'
                else 'to_date(''' ||
                        to_char(a_Value.DateValue, 'YYYY-MM-DD') ||
                        ''', ''YYYY-MM-DD'')' end || ', ' ||
                case when a_Value.TimestampValue is null then 'null'
                else 'to_timestamp(''' || to_char(a_Value.TimestampValue,
                        'YYYY-MM-DD HH24:MI:SS') ||
                        ''', ''YYYY-MM-DD HH24:MI:SS'')' end || ', ' ||
                case when a_Value.BooleanValue is null then 'null'
                when a_Value.BooleanValue then 'true'
                else 'false' end || ')';
    end;

    procedure TestOut (
        a_Value             out nocopy udt_Record
    ) is
    begin
        a_Value.NumberValue := 25;
        a_Value.StringValue := 'String in record';
        a_Value.DateValue := to_date(20160216, 'YYYYMMDD');
        a_Value.TimestampValue := to_timestamp('20160216 18:23:55',
                'YYYYMMDD HH24:MI:SS');
        a_Value.BooleanValue := true;
    end;

    function TestInArrays (
        a_Value             udt_RecordArray
    ) return varchar2 is
        t_Result            varchar2(4000);
    begin
        for i in 0..a_Value.count - 1 loop
            if t_Result is not null then
                t_Result := t_Result || '; ';
            end if;
            t_Result := t_Result || GetStringRep(a_Value(i));
        end loop;
        return t_Result;
    end;

end;
/

exit

