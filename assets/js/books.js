var xmlHttp = createXmlHttpRequestObject();

function createXmlHttpRequestObject(){
	var xmlHttp;
	try{
		xmlHttp=new XMLHttpRequest();
	}
	catch(e){
		var XmlHttpVersions=new Array ("MSXML2.XMLHTTP.6.0",
										"MSXML2.XMLHTTP.5.0",
										"MSXML2.XMLHTTP.4.0",
										"MSXML2.XMLHTTP.3.0",
										"MSXML2.XMLHTTP",
										"Microsoft.XMLHTTP");
		for(var i=0; i<XmlHttpVersions.length && !xmlHttp; i++){
			try{
				xmlHttp=new ActiveXObject(XmlHttpVersions[i]);
			}
			catch(e){}
		}
	}
	if(!xmlHttp)
		alert("Ошибка создания объекта XMLHttpRequest.");
	else 
		return xmlHttp;
}

function process(){
	if (xmlHttp){
		try{
			xmlHttp.open("GET", "books.xml", true);
			xmlHttp.onreadystatechange = handleRequestStateChange;
			xmlHttp.send(null);
		}
		catch(e){
			alert("Невозможно соединиться с сервером:\n" + e.toString());
		}
	}
}

function handleRequestStateChange(){
	if(xmlHttp.readyState==4){
		if(xmlHttp.status==200){
			try{
				handleServerResponse();
			}
			catch(e){
				alert("Ошибка чтения ответа: " + e.toString());
			}
		}
		else{
			alert("Возникли проблемы во время получения данных:\n" + xmlHttp.statusText);
		}
	}
}

function handleServerResponse(){
	var xmlResponse=xmlHttp.responseXML;
	if (!xmlResponse || !xmlResponse.documentElement) {
		throw("Неверная структура документа XML:\n" + xmlHttp.responseText);
		var rootNodeName=xmlResponse.documentElement.nodeName;
	}
	if (rootNodeName=="parseerror") {
		throw("Неверная структура документа XML:\n" + xmlHttp.responseText);
	}
	xmlRoot=xmlResponse.documentElement;
	titleArray=xmlRoot.getElementsByTagName("title");
	isbnArray=xmlRoot.getElementsByTagName("isbn");
	var html = "";
	for(var i=0; i<titleArray.length; i++){
		html+=titleArray.item(i).firstChild.data+","+isbnArray.item(i).firstChild.data+"</br>";
	}
	myDiv=document.getElementById("myDivElement");
	myDiv.innerHTML="Сервер говорит: <br />"+html;
}