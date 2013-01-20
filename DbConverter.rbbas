#tag Class
Protected Class DbConverter
	#tag Method, Flags = &h21
		Private Sub CheckDBForErrors()
		  If RealDb.Error then
		    MsgBox("SQLite DB error:  " + RealDB.ErrorMessage)
		    Raise New RuntimeException
		  end if
		  
		  If PgDb.Error then
		    MsgBox("PostgreSQL error:  " + PgDb.ErrorMessage)
		    Raise New RuntimeException
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ClearPgData()
		  pgDb.SQLExecute("delete from purchaseorderscratchpad")
		  pgDb.SQLExecute("delete from salesorderlineitems")
		  pgDb.SQLExecute("delete from purchaseorderlineitems")
		  pgDb.SQLExecute("delete from salesorders")
		  pgDb.SQLExecute("delete from purchaseorders")
		  pgDb.SQLExecute("delete from productlineitems")
		  pgDb.SQLExecute("delete from productinventory")
		  pgDb.SQLExecute("delete from products")
		  pgDb.SQLExecute("delete from componentinventory")
		  pgDb.SQLExecute("delete from customers")
		  pgDb.SQLExecute("delete from vendors")
		  pgDb.SQLExecute("delete from categories")
		  pgDb.SQLExecute("delete from variables")
		  pgDb.SQLExecute("delete from preferences")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertCategories()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select categoryid,categoryname from categories")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    rec.IntegerColumn("categoryid") = rs.IdxField(1).IntegerValue
		    rec.Column("categoryname") = rs.IdxField(2).StringValue
		    PgDb.InsertRecord("categories", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ConvertDatabase() As Boolean
		  RealDb = new REALSQLDatabase
		  RealDb.DatabaseFile = GetFolderItem(RealDbFilePath)
		  If not RealDb.Connect then
		    MsgBox RealDb.ErrorMessage
		    Return False
		  end if
		  
		  PgDb = new PostgreSQLDatabase
		  PgDb.Host = pgHost
		  PgDb.Port = pgPort
		  PgDb.DatabaseName = pgDatabaseName
		  PgDb.UserName = pgUser
		  PgDb.Password = pgPassword
		  If not PgDb.Connect then
		    MsgBox PgDb.ErrorMessage
		    return False
		  end if
		  
		  try
		    ClearPgData
		    
		    ConvertPreferences
		    ConvertVariables
		    
		    ConvertCategories
		    ConvertVendors
		    'ConvertCustomers
		    '
		    'ConvertComponentInventory
		    'ConvertProducts
		    '
		    '
		    'ConvertProductInventory
		    'ConvertProductLineItems
		    'ConvertPurchaseOrders
		    'ConvertSalesOrders
		    '
		    'ConvertPurchaseOrderLineItems
		    'ConvertSalesOrderLineItems
		    '
		    'ConvertPurchaseOrderScratchpad
		  catch err as RuntimeException
		    return false
		  end try
		  
		  Return True
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertPreferences()
		  'pull all records out of sqlite Preferences table
		  
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select preferencename, preferencevalue from preferences")
		  
		  CheckDBForErrors()
		  
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    rec.Column("preferencename") = rs.IdxField(1).StringValue
		    rec.Column("preferencevalue") = rs.IdxField(2).StringValue
		    PgDb.InsertRecord("preferences", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertVariables()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select id,name,value from variables")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    rec.IntegerColumn("id") = rs.IdxField(1).IntegerValue
		    rec.Column("name") = rs.IdxField(2).StringValue
		    rec.Column("value") = rs.IdxField(3).StringValue
		    PgDb.InsertRecord("variables", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertVendors()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select vendorid, companyname, contact, webaddress ,phone, fax, address,city, state, postalcode, notes from vendors")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    
		    rec.IntegerColumn("vendorid") = rs.IdxField(1).IntegerValue
		    rec.Column("companyname") = rs.IdxField(2).StringValue
		    rec.Column("contact") = rs.IdxField(3).StringValue
		    rec.Column("webaddress") = rs.IdxField(4).StringValue
		    rec.Column("phone") = rs.IdxField(5).StringValue
		    rec.Column("fax") = rs.IdxField(6).StringValue
		    rec.Column("address") = rs.IdxField(7).StringValue
		    rec.Column("city") = rs.IdxField(8).StringValue
		    rec.Column("state") = rs.IdxField(9).StringValue
		    rec.Column("postalcode") = rs.IdxField(10).StringValue
		    rec.Column("notes") = rs.IdxField(11).StringValue
		    
		    PgDb.InsertRecord("vendors", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		  
		  'reset sequence
		  PgDb.SQLExecute("select setval('vendors_vendorid_seq', (select max(vendorid) from vendors))")
		  CheckDBForErrors()
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		pgDatabaseName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private PgDb As PostgreSQLDatabase
	#tag EndProperty

	#tag Property, Flags = &h0
		pgHost As String
	#tag EndProperty

	#tag Property, Flags = &h0
		pgPassword As String
	#tag EndProperty

	#tag Property, Flags = &h0
		pgPort As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		pgUser As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RealDb As REALSQLDatabase
	#tag EndProperty

	#tag Property, Flags = &h0
		RealDbFilePath As String
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="pgDatabaseName"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="pgHost"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="pgPassword"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="pgPort"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="pgUser"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RealDbFilePath"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
