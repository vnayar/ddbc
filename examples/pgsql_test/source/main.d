import std.stdio;

import ddbc.all;
import ddbc.pods;

int main(string[] argv)
{
    string[string] params;
    // This part depends on RDBMS
    version( USE_PGSQL )
    {
        PGSQLDriver driver = new PGSQLDriver();
        string url = PGSQLDriver.generateUrl( "/tmp", 5432, "ddbctestdb" );
        params["user"] = "ddbctest";
        params["password"] = "ddbctestpass";
        params["ssl"] = "true";
    }
    else version( USE_SQLITE )
    {
        SQLITEDriver driver = new SQLITEDriver();
        string url = "zzz.db"; // file with DB
    }
    else version(USE_MYSQL)
    {
        // MySQL driver - you can use PostgreSQL or SQLite instead as well
        MySQLDriver driver = new MySQLDriver();
        string url = MySQLDriver.generateUrl("localhost", 3306, "test_db");
        params = MySQLDriver.setUserAndPassword("testuser", "testpassword");
    }

    // create connection pool
    DataSource ds = new ConnectionPoolDataSourceImpl(driver, url, params);

    // creating Connection
    auto conn = ds.getConnection();
    scope(exit) conn.close();

    // creating Statement
    auto stmt = conn.createStatement();
    scope(exit) stmt.close();

    import std.conv : to;
    writeln("Hello D-World!");
    // execute simple queries to create and fill table
    stmt.executeUpdate("DROP TABLE IF EXISTS ddbct1");
    stmt.executeUpdate("CREATE TABLE ddbct1 
                       (id bigint not null primary key, 
                       name varchar(250),
                       comment text, 
                       ts timestamp)");
    //conn.commit();
    stmt.executeUpdate("INSERT INTO ddbct1 (id, name, comment, ts) VALUES
                       (1, 'name1', 'comment for line 1', '2016/09/14 15:24:01')");
    stmt.executeUpdate("INSERT INTO ddbct1 (id, name, comment) VALUES
                       (2, 'name2', 'comment for line 2 - can be very long')");
    stmt.executeUpdate("INSERT INTO ddbct1 (id, name) values(3, 'name3')"); // comment is null here

    // reading DB
    auto rs = stmt.executeQuery("SELECT id, name name_alias, comment, ts FROM ddbct1 ORDER BY id");
    while (rs.next())
        writeln(to!string(rs.getLong(1)), "\t", rs.getString(2), "\t", rs.getString(3), "\t", rs.getString(4));

    ubyte[] bin_data = [1, 2, 3, 'a', 'b', 'c', 0xFE, 0xFF, 0, 1, 2];
    stmt.executeUpdate("DROP TABLE IF EXISTS bintest");
    stmt.executeUpdate("CREATE TABLE bintest (id bigint not null primary key, blob1 bytea)");
    PreparedStatement ps = conn.prepareStatement("INSERT INTO bintest (id, blob1) VALUES (1, ?)");
    ps.setUbytes(1, bin_data);
    ps.executeUpdate();
    struct Bintest {
        long id;
        ubyte[] blob1;
    }
    Bintest[] rows;
    foreach(e; stmt.select!Bintest)
        rows ~= e;
    //stmt!
    auto rs2 = stmt.executeQuery("SELECT id, blob1 FROM bintest WHERE id=1");
    if (rs2.next()) {
        ubyte[] res = rs2.getUbytes(2);
        assert(res == bin_data);
    }

    stmt.executeUpdate("DROP TABLE IF EXISTS guidtest");
    stmt.executeUpdate("CREATE TABLE guidtest (guid uuid not null primary key, name text)");
    stmt.executeUpdate("INSERT INTO guidtest (guid, name) VALUES ('cd3c7ffd-7919-f6c5-999d-5586d9f3b261', 'vasia')");
    struct Guidtest {
        string guid;
        string name;
    }
    Guidtest[] guidrows;
    foreach(e; stmt.select!Guidtest)
        guidrows ~= e;
    writeln(guidrows);

    return 0;
}