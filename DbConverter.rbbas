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
		  pgDb.Commit
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

	#tag Method, Flags = &h21
		Private Sub ConvertComponentInventory()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select componentid, componentname, image, inventoryquantity, primaryvendorid, primaryvendorcost, primaryvendorsku, alternatevendorid, alternatevendorcost, alternatevendorsku, manufacturer, manufacturersku from componentinventory")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    
		    rec.IntegerColumn("componentid") = rs.Field("componentid").IntegerValue
		    rec.Column("componentname") = rs.Field("componentname").StringValue
		    rec.Column("image") = EncodeBase64(rs.Field("image").Value, 0)
		    rec.CurrencyColumn("inventoryquantity") = rs.Field("inventoryquantity").CurrencyValue
		    if rs.Field("primaryvendorid").IntegerValue <> 0 then
		      rec.IntegerColumn("primaryvendorid") = rs.Field("primaryvendorid").IntegerValue
		    end
		    rec.CurrencyColumn("primaryvendorcost") = rs.Field("primaryvendorcost").CurrencyValue
		    rec.Column("primaryvendorsku") = rs.Field("primaryvendorsku").StringValue
		    if rs.Field("alternatevendorid").IntegerValue <> 0 then
		      rec.IntegerColumn("alternatevendorid") = rs.Field("alternatevendorid").IntegerValue
		    end if
		    rec.CurrencyColumn("alternatevendorcost") = rs.Field("alternatevendorcost").CurrencyValue
		    rec.Column("alternatevendorsku") = rs.Field("alternatevendorsku").StringValue
		    rec.Column("manufacturer") = rs.Field("manufacturer").StringValue
		    rec.Column("manufacturersku") = rs.Field("manufacturersku").StringValue
		    
		    PgDb.InsertRecord("componentinventory", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		  
		  'reset sequence
		  PgDb.SQLExecute("select setval('componentinventory_componentid_seq', (select max(componentid) from componentinventory))")
		  CheckDBForErrors()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertCustomers()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select customerid, companyname, contact, webaddress ,phone, fax, billingaddress,billingcity, billingstate, billingpostalcode, shippingaddress, shippingcity, shippingstate, shippingpostalcode, notes from customers")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    
		    rec.IntegerColumn("customerid") = rs.IdxField(1).IntegerValue
		    rec.Column("companyname") = rs.IdxField(2).StringValue
		    rec.Column("contact") = rs.IdxField(3).StringValue
		    rec.Column("webaddress") = rs.IdxField(4).StringValue
		    rec.Column("phone") = rs.IdxField(5).StringValue
		    rec.Column("fax") = rs.IdxField(6).StringValue
		    rec.Column("billingaddress") = rs.IdxField(7).StringValue
		    rec.Column("billingcity") = rs.IdxField(8).StringValue
		    rec.Column("billingstate") = rs.IdxField(9).StringValue
		    rec.Column("billingpostalcode") = rs.IdxField(10).StringValue
		    rec.Column("shippingaddress") = rs.IdxField(11).StringValue
		    rec.Column("shippingcity") = rs.IdxField(12).StringValue
		    rec.Column("shippingstate") = rs.IdxField(13).StringValue
		    rec.Column("shippingpostalcode") =rs.IdxField(14).StringValue
		    rec.Column("notes") = rs.IdxField(15).StringValue
		    
		    PgDb.InsertRecord("customers", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		  
		  'reset sequence
		  PgDb.SQLExecute("select setval('customers_customerid_seq', (select max(customerid) from customers))")
		  CheckDBForErrors()
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
		    ConvertCustomers
		    
		    ConvertComponentInventory
		    ConvertProducts
		    
		    ConvertProductLineItems
		    ConvertPurchaseOrders
		    ConvertSalesOrders
		    
		    ConvertProductInventory
		    ConvertPurchaseOrderLineItems
		    ConvertSalesOrderLineItems
		    
		    ConvertPurchaseOrderScratchpad
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
		Private Sub ConvertProductInventory()
		  Dim rs as RecordSet
		  Dim salesRs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select productid, serialnumber, manufacturedate, salesorderid from productinventory")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    
		    rec.IntegerColumn("productid") = rs.Field("productid").IntegerValue
		    rec.IntegerColumn("serialnumber") = rs.Field("serialnumber").IntegerValue
		    rec.DateColumn("manufacturedate") = rs.Field("manufacturedate").DateValue
		    
		    'check for sales order existing
		    salesRs = PgDb.SQLSelect("select * from salesorders where salesorderid = " + Cstr(rs.Field("salesorderid").IntegerValue))
		    if not salesRs.EOF then
		      rec.IntegerColumn("salesorderid") = rs.Field("salesorderid").IntegerValue
		    end if
		    
		    PgDb.InsertRecord("productinventory", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		  
		  'reset sequence
		  PgDb.SQLExecute("select setval('productinventory_serialnumber_seq', (select max(productid) from productinventory))")
		  CheckDBForErrors()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertProductLineItems()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select productid,  componentid, componentquantity, issubassembly, subassemblyproductid   from productlineitems")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    
		    rec.IntegerColumn("productid") = rs.Field("productid").IntegerValue
		    rec.IntegerColumn("componentid") = rs.Field("componentid").IntegerValue
		    rec.CurrencyColumn("componentquantity") = rs.Field("componentquantity").CurrencyValue
		    if  rs.Field("issubassembly").BooleanValue then
		      rec.BooleanColumn("issubassembly") = rs.Field("issubassembly").BooleanValue
		      rec.IntegerColumn("subassemblyproductid") = rs.Field("subassemblyproductid").IntegerValue
		    else
		      rec.BooleanColumn("issubassembly") = rs.Field("issubassembly").BooleanValue
		    end if
		    
		    PgDb.InsertRecord("productlineitems", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		  
		  'reset sequence
		  PgDb.SQLExecute("select setval('productlineitems_id_seq', (select max(id) from productlineitems))")
		  CheckDBForErrors()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertProducts()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select productid, productname, image, price from products")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    
		    rec.IntegerColumn("productid") = rs.Field("productid").IntegerValue
		    rec.Column("productname") = rs.Field("productname").StringValue
		    rec.Column("image") = EncodeBase64(rs.Field("image").Value, 0)
		    rec.CurrencyColumn("price") = rs.Field("price").CurrencyValue
		    
		    PgDb.InsertRecord("products", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		  
		  'reset sequence
		  PgDb.SQLExecute("select setval('products_productid_seq', (select max(productid) from products))")
		  CheckDBForErrors()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertPurchaseOrderLineItems()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select purchaseorderid, componentid, quantity, datereceived, received from purchaseorderlineitems")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    
		    rec.IntegerColumn("purchaseorderid") = rs.Field("purchaseorderid").IntegerValue
		    rec.IntegerColumn("componentid") = rs.Field("componentid").IntegerValue
		    rec.DateColumn("datereceived") = rs.Field("datereceived").DateValue
		    rec.CurrencyColumn("quantity") = rs.Field("quantity").CurrencyValue
		    rec.BooleanColumn("received") = rs.Field("received").BooleanValue
		    
		    PgDb.InsertRecord("purchaseorderlineitems", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		  
		  'reset sequence
		  PgDb.SQLExecute("select setval('purchaseorderlineitems_id_seq', (select max(id) from purchaseorderlineitems))")
		  CheckDBForErrors()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertPurchaseOrders()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select purchaseorderid, vendorid, dateordered, shippingmethod, complete from purchaseorders")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    
		    rec.IntegerColumn("purchaseorderid") = rs.Field("purchaseorderid").IntegerValue
		    rec.IntegerColumn("vendorid") = rs.Field("vendorid").IntegerValue
		    rec.DateColumn("dateordered") = rs.Field("dateordered").DateValue
		    rec.Column("shippingmethod") = rs.Field("shippingmethod").StringValue
		    rec.BooleanColumn("complete") = rs.Field("complete").BooleanValue
		    
		    PgDb.InsertRecord("purchaseorders", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		  
		  'reset sequence
		  PgDb.SQLExecute("select setval('purchaseorders_purchaseorderid_seq', (select max(purchaseorderid) from purchaseorders))")
		  CheckDBForErrors()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertPurchaseOrderScratchpad()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select componentid, componentquantity, primaryvendorid, alternatevendorid from purchaseorderscratchpad")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    
		    rec.IntegerColumn("componentid") = rs.Field("componentid").IntegerValue
		    rec.IntegerColumn("primaryvendorid") = rs.Field("primaryvendorid").IntegerValue
		    rec.IntegerColumn("alternatevendorid") = rs.Field("alternatevendorid").IntegerValue
		    rec.CurrencyColumn("componentquantity") = rs.Field("componentquantity").CurrencyValue
		    
		    PgDb.InsertRecord("purchaseorderscratchpad", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertSalesOrderLineItems()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select salesorderid, productid, quantity, shippeddate, shipped from salesorderlineitems")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    
		    rec.IntegerColumn("salesorderid") = rs.Field("salesorderid").IntegerValue
		    rec.IntegerColumn("productid") = rs.Field("productid").IntegerValue
		    rec.DateColumn("shippeddate") = rs.Field("shippeddate").DateValue
		    rec.CurrencyColumn("quantity") = rs.Field("quantity").CurrencyValue
		    rec.BooleanColumn("shipped") = rs.Field("shipped").BooleanValue
		    
		    PgDb.InsertRecord("salesorderlineitems", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		  
		  'reset sequence
		  PgDb.SQLExecute("select setval('salesorderlineitems_id_seq', (select max(id) from salesorderlineitems))")
		  CheckDBForErrors()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConvertSalesOrders()
		  Dim rs as RecordSet
		  Dim rec as DatabaseRecord
		  
		  rs = RealDb.SQLSelect("select salesorderid, customerid, dateordered, shippingmethod, shipperaccount, complete from salesorders")
		  CheckDBForErrors()
		  rs.MoveFirst
		  
		  while not rs.EOF
		    rec = New DatabaseRecord()
		    
		    rec.IntegerColumn("salesorderid") = rs.Field("salesorderid").IntegerValue
		    rec.IntegerColumn("customerid") = rs.Field("customerid").IntegerValue
		    rec.DateColumn("dateordered") = rs.Field("dateordered").DateValue
		    rec.Column("shippingmethod") = rs.Field("shippingmethod").StringValue
		    rec.Column("shipperaccount") = rs.Field("shipperaccount").StringValue
		    rec.BooleanColumn("complete") = rs.Field("complete").BooleanValue
		    
		    PgDb.InsertRecord("salesorders", rec)
		    CheckDBForErrors()
		    rs.MoveNext
		  wend
		  
		  'reset sequence
		  PgDb.SQLExecute("select setval('salesorders_salesorderid_seq', (select max(salesorderid) from salesorders))")
		  CheckDBForErrors()
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
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="pgHost"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="pgPassword"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
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
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RealDbFilePath"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
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
