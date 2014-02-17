<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns="http://www.w3.org/ns/wsdl" xmlns:w11="http://schemas.xmlsoap.org/wsdl/" xmlns:w11soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:w11http="http://schemas.xmlsoap.org/wsdl/http/" xmlns:w11mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:soapenc11="http://schemas.xmlsoap.org/soap/encoding/" xmlns:soap11="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:wsdli="http://www.w3.org/ns/wsdl-instance" xmlns:wsdlx="http://www.w3.org/ns/wsdl-extensions" xmlns:wrpc="http://www.w3.org/ns/wsdl/rpc" xmlns:wsoap="http://www.w3.org/ns/wsdl/soap" xmlns:whttp="http://www.w3.org/ns/wsdl/http" exclude-result-prefixes="w11 w11soap w11http w11mime soap11 soapenc11         xs xsi wsoap whttp wrpc wsdli wsdlx">

  <xsl:strip-space elements="*"/>

  <xsl:output method="xml" media-type="application/xhtml+xml" omit-xml-declaration="yes" encoding="utf-8" indent="yes"/>

  <xsl:template match="/">
    <xsl:apply-templates select="w11:definitions"/>
  </xsl:template>

  <xsl:template name="converter-doc">
    <xsl:text>
    </xsl:text>
    <xsl:comment>

      Documentation at:
      http://esw.w3.org/topic/WsdlConverter

      To report problems, please refer to:
      http://esw.w3.org/topic/WsdlConverterFeedback

      Generated by the WSDL converter version:
      2006-02-20
      
    </xsl:comment>
    <xsl:text>
    </xsl:text>
  </xsl:template>

  <xsl:variable name="type" select="/w11:definitions/w11:binding[1]"/>
  <xsl:variable name="qname" select="resolve-QName($type/@type, $type)"/>

  <xsl:template match="w11:definitions">
    <description targetNamespace="{@targetNamespace}">
      <!-- creating namespace declarations -->
      <xsl:namespace name="{prefix-from-QName($qname)}" select="namespace-uri-from-QName($qname)"/>

      <xsl:call-template name="converter-doc"/>
      
      <xsl:apply-templates select="w11:documentation"/>

      <xsl:choose>
	<xsl:when test="not(w11:types)">
	  <types>
	    <xsl:apply-templates select="/w11:definitions/w11:import" mode="types"/>
	    <xsl:apply-templates select="//w11soap:body" mode="rpctypes"/>
	    <xsl:call-template name="httpUrlReplacementSchemaDecl"/>
	  </types>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates select="w11:types"/>
	</xsl:otherwise>
      </xsl:choose>

      <xsl:apply-templates select="*[not((local-name()=&quot;import&quot;               or local-name()=&quot;documentation&quot;        or local-name()=&quot;types&quot;)              and namespace-uri()=&quot;http://schemas.xmlsoap.org/wsdl/&quot;)]"/>
    </description>
  </xsl:template>

  <xsl:template name="resolve-soaprpc-element-localname">
    <xsl:param name="msg"/>
    <xsl:choose>
      <xsl:when test="local-name($msg) = 'input'">
	<xsl:value-of select="$msg/../@name"/>
      </xsl:when>
      <xsl:when test="local-name($msg) = 'output'">
	<!-- @@@ Not 100% sure about this one -->
	<xsl:value-of select="concat(../../@name, 'Response')"/>
      </xsl:when>
      <xsl:otherwise>
	<!-- @@@ I don't think that we can do anything for faults -->
	<xsl:value-of select="'#any'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="w11soap:body" mode="rpctypes">
    <xsl:variable name="soapbody" select="."/>
    <xsl:if test="$soapbody/../../@style = 'rpc'       or $soapbody/../../../w11soap:binding/@style = 'rpc'">
      <xsl:variable name="message_name" select="resolve-QName(../@message, ..)"/>
      <xsl:variable name="message" select="/w11:definitions/w11:message[QName(/w11:definitions/@targetNamespace, @name) eq $message_name]"/>
      <xsl:variable name="parts" select="tokenize($soapbody/@parts, '\s+')"/>
      <xsl:variable name="usestypes">
	<xsl:call-template name="message-is-using-types">
	  <xsl:with-param name="parts" select="$parts"/>
	  <xsl:with-param name="message" select="$message"/>
	  <xsl:with-param name="name" select="current()"/>
	</xsl:call-template>
      </xsl:variable>
      <xsl:if test="not($usestypes='true')"> 
	<xsl:variable name="localName">
	  <xsl:call-template name="resolve-soaprpc-element-localname">
	    <xsl:with-param name="msg" select=".."/>
	  </xsl:call-template>
	</xsl:variable>
	<xsl:if test="$localName != '#any'">
	  <xs:schema targetNamespace="{@namespace}">
	    <xs:element name="{$localName}">
	      <xs:complexType>
		<xs:sequence>
		  <xsl:for-each select="$parts">
		    <xsl:variable name="part" select="$message/w11:part[@name = current()]"/>
		    <xsl:variable name="element" select="resolve-QName($part/@element, $part)"/>
		    <xs:element ref="{$element}">
		      <xsl:namespace name="{prefix-from-QName($element)}" select="namespace-uri-from-QName($element)"/>
		    </xs:element>
		  </xsl:for-each>
		</xs:sequence>
	      </xs:complexType>
	    </xs:element>
	  </xs:schema>
	</xsl:if>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template match="w11:definitions/w11:import">
    <xsl:choose>
      <xsl:when test="@location and doc-available(@location)">
	<xsl:variable name="nodes" select="doc(@location)"/>
	<xsl:choose>
	  <xsl:when test="$nodes/w11:definitions">
	    <import namespace="{@namespace}" location="{@location}"/>
	  </xsl:when>
	  <xsl:when test="$nodes/xs:schema">
	    <!-- move to wsdl20:description/wsdl20:types
	         see match=wsdl20:description/wsdl20:types
                     and match=wsdl20:description/wsdl20:portType-->
	  </xsl:when>
	  <xsl:when test="count($nodes) = 0">
	    <import namespace="{@namespace}" location="{@location}"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <!-- No WSDL 2.0 components found at <xsl:value-of
	      select='@location' /> in namespace <xsl:value-of
	      select='@namespace' /> -->
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<import namespace="{@namespace}"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="w11:definitions/w11:import" mode="types">
    <!-- check if an WSDL 1.1 import was about XSD -->
    <xsl:if test="@location and doc-available(@location)     and doc(@location)/xs:schema">
      <!-- move to wsdl20:description/wsdl20:types -->
      <xs:import namespace="{@namespace}" schemaLocation="{@location}"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="w11:types">
    <types>
      <xsl:apply-templates select="/w11:definitions/w11:import" mode="types"/>
      <xsl:apply-templates select="xs:schema"/>
      <xsl:apply-templates select="*[not(local-name()=&quot;schema&quot;              and namespace-uri()=&quot;http://www.w3.org/2001/XMLSchema&quot;)]"/>
      <xsl:apply-templates select="//w11soap:body" mode="rpctypes"/>
      <xsl:call-template name="httpUrlReplacementSchemaDecl"/>
    </types>
  </xsl:template>

  <xsl:template name="httpUrlReplacementSchemaDecl">
    <!-- Convert message parts with using types that are used in an HTTP binding -->	 
    <!-- FIXME: currently only works with input; how about output? -->
    <xsl:for-each select="//w11:message">
      <xsl:variable name="themessage" select="."/>
      <xsl:variable name="message_name" select="QName(/w11:definitions/@targetNamespace, @name)"/>
      <xsl:variable name="operation" select="//w11:portType/w11:operation[resolve-QName(w11:input/@message, .) = $message_name]"/>
      <xsl:for-each select="$operation">
	<xsl:variable name="operation_name" select="@name"/>
	<xsl:variable name="porttype_name" select="QName(/w11:definitions/@targetNamespace, ../@name)"/>
	<xsl:variable name="bound_to_http">
	  <xsl:for-each select="//w11:binding[resolve-QName(@type, .) = $porttype_name]/w11:operation[@name = $operation_name]">
	    <xsl:if test="../w11http:binding">
	      <xsl:text>y</xsl:text>
	    </xsl:if>
	  </xsl:for-each>
	</xsl:variable>
	<xsl:if test="contains($bound_to_http, 'y')">
	  <xs:schema targetNamespace="{concat(/w11:definitions/@targetNamespace, 'GEN')}">
	    <xs:documentation>	 
	      The following is made up by the translation script.	 
	      It's not clear how well this is going to work.	 
	    </xs:documentation>	 
	    
	    <xs:element name="{$operation_name}">
	      <xs:complexType>
		<xsl:for-each select="$themessage/w11:part">
		  <xs:element name="{@name}" type="{@type}"/>
		</xsl:for-each>
	      </xs:complexType>
	    </xs:element>
	  </xs:schema>
	</xsl:if>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="w11:message">
<!--    <xsl:comment>MESSAGE:<xsl:value-of select='@name' /></xsl:comment> -->
  </xsl:template>

  <xsl:template match="w11:portType">
    <interface name="{@name}">
      <xsl:apply-templates select="w11:documentation"/>
      <xsl:apply-templates select="*[not(local-name()=&quot;documentation&quot;              and namespace-uri()=&quot;http://schemas.xmlsoap.org/wsdl/&quot;)]"/>
    </interface>
  </xsl:template>

  <xsl:template match="w11:portType/w11:operation">
    <xsl:apply-templates select="w11:fault"/>
    <xsl:variable name="name" select="@name"/>
    <operation name="{$name}">
      <xsl:variable name="ios" select="*[(local-name()=&quot;input&quot;               or local-name()=&quot;output&quot;               or local-name()=&quot;fault&quot;)              and namespace-uri()=&quot;http://schemas.xmlsoap.org/wsdl/&quot;]"/>
      <!-- pattern is not optional in WSDL 2.0 -->
      <xsl:variable name="pattern">
	<xsl:choose>
	  <xsl:when test="count($ios) = 1      and $ios/self::w11:input">
	    <!-- One-Way Operation -->
	    <xsl:text>http://www.w3.org/ns/wsdl/in-only</xsl:text>
	  </xsl:when>
	  <xsl:when test="count($ios) = 2      and $ios/self::w11:input      and $ios/self::w11:fault">
	    <xsl:text>http://www.w3.org/ns/wsdl/robust-in-only</xsl:text>
	  </xsl:when>
	  <xsl:when test="count($ios) = 1      and $ios/self::w11:output">
	    <!-- Notification Operation -->
	    <xsl:text>http://www.w3.org/ns/wsdl/out-only</xsl:text>
	  </xsl:when>
	  <xsl:when test="count($ios) = 2      and $ios/self::w11:output      and $ios/self::w11:fault">
	    <xsl:text>http://www.w3.org/ns/wsdl/robust-out-only</xsl:text>
	  </xsl:when>
	  <xsl:when test="count($ios/self::w11:input) = 1      and count($ios/self::w11:output) = 1      and $ios/self::w11:output[preceding-sibling::w11:input]">
	    <!-- Request-Response Operation -->
	    <xsl:text>http://www.w3.org/ns/wsdl/in-out</xsl:text>
	  </xsl:when>
	  <xsl:when test="count($ios/self::w11:output) = 1      and count($ios/self::w11:input) = 1      and $ios/self::w11:input[preceding-sibling::w11:output]">
	    <!-- Solicit-Response Operation -->
	    <xsl:text>http://www.w3.org/ns/wsdl/out-in</xsl:text>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:text>http://www.w3.org/2006/02/undefined</xsl:text>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:variable>
      <xsl:attribute name="pattern">
	<xsl:value-of select="$pattern"/>
      </xsl:attribute>
      <xsl:if test="count(../w11:operation[@name=$name]) &gt; 1">
	<!-- WSDL 1.1 operation/@name are unique according to
	     the WS-I Basic profile but input/output are -->
	<documentation>
	  ERROR: duplicate name for the operation
	</documentation>
      </xsl:if>
      <xsl:apply-templates select="w11:documentation"/>

      <xsl:for-each select="$ios">
	<xsl:choose>
	  <xsl:when test="self::w11:input or self::w11:output">
	    <xsl:apply-templates select="."/>
	  </xsl:when>
	  <xsl:when test="self::w11:fault">
	    <xsl:choose>
	      <xsl:when test="$pattern = &quot;http://www.w3.org/ns/wsdl/out-in&quot;          or $pattern = &quot;http://www.w3.org/ns/wsdl/out-opt-in&quot;">
		<xsl:apply-templates select="." mode="infault"/>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:apply-templates select="." mode="outfault"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:when>
	</xsl:choose>
      </xsl:for-each>
    </operation>
  </xsl:template>

  <xsl:template match="w11:portType/w11:operation/w11:input                        |w11:portType/w11:operation/w11:output                        |w11:portType/w11:operation/w11:fault">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/ns/wsdl">
      <xsl:call-template name="resolve-elementType"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="w11:fault" mode="infault">
    <xsl:variable name="prefix">
      <xsl:value-of select="prefix-from-QName($qname)"/>
    </xsl:variable>
		  
    <infault ref="{$prefix}:{@name}">
      <xsl:namespace name="{prefix}" select="/w11:definitions/@targetNamespace"/>
    </infault>
  </xsl:template>

  <xsl:template match="w11:fault" mode="outfault">
    <xsl:variable name="prefix">
      <xsl:value-of select="prefix-from-QName($qname)"/>
    </xsl:variable>
		  
    <outfault ref="{$prefix}:{@name}">
      <xsl:namespace name="{$prefix}" select="/w11:definitions/@targetNamespace"/>
    </outfault>
  </xsl:template>

  <xsl:template match="w11:fault" mode="binding">
    <xsl:variable name="prefix">
      <xsl:value-of select="prefix-from-QName($qname)"/>
    </xsl:variable>
		  
    <fault ref="{$prefix}:{@name}">
      <xsl:namespace name="{$prefix}" select="/w11:definitions/@targetNamespace"/>
    </fault>
  </xsl:template>

  <xsl:template name="resolve-elementType-attrs">
    <!-- This template is called by resolve-elementType to set attribute values -->
    <xsl:param name="element"/>
    <xsl:param name="faultname"/>
    <xsl:choose>
      <xsl:when test="self::w11:fault">
	<xsl:attribute name="name">
	  <xsl:value-of select="$faultname"/>
	</xsl:attribute>
	<xsl:attribute name="element"><xsl:value-of select="$element"/></xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
	<xsl:attribute name="element"><xsl:value-of select="$element"/></xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="message-is-using-types">
    <xsl:param name="parts"/>
    <xsl:param name="message"/>
    <xsl:param name="name"/>
    <xsl:variable name="usestypes">
      <xsl:for-each select="$parts">
	<xsl:variable name="bodypart" select="$message/w11:part[@name eq $name]"/>
	<xsl:if test="$bodypart/@type         and not($bodypart/@element)">
	  <xsl:value-of select="'y'"/>
	</xsl:if>
      </xsl:for-each>    
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="contains($usestypes, 'y')">
	<xsl:value-of select="true()"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="resolve-elementType">    
    <xsl:variable name="message_name" select="resolve-QName(@message, .)"/>
    <xsl:variable name="message" select="/w11:definitions/w11:message[QName(/w11:definitions/@targetNamespace, @name) eq $message_name]"/>
    <xsl:variable name="portType_name" select="QName(/w11:definitions/@targetNamespace, ../../@name)"/>
    <xsl:variable name="operation_name" select="../@name"/>
    <xsl:variable name="bound_operation" select="//w11:binding[resolve-QName(@type, current()) = $portType_name]/w11:operation[@name=$operation_name]"/>
    <!-- FIXME: this has a good chance of breaking if the message is bound more than once -->
    <!-- FIXME: Only running tests on one operation, and will fail if @message is missing on input  -->
    <xsl:variable name="soapbody" select="$bound_operation/w11:input[resolve-QName(@message, current())=$message_name]/w11soap:body|$bound_operation/w11:output[resolve-QName(@message, current())=$message_name]/w11soap:body"/>
    <xsl:variable name="parts" select="tokenize($soapbody/@parts, '\s+')"/>
    <xsl:choose>
      <!-- Is this SOAP RPC? -->
      <xsl:when test="$soapbody/../../@style = 'rpc'         or $soapbody/../../../w11soap:binding/@style = 'rpc'">
	<!-- Check that all parts are defined with elements -->
	<xsl:variable name="usestypes">
	  <xsl:call-template name="message-is-using-types">
	    <xsl:with-param name="parts" select="$parts"/>
	    <xsl:with-param name="message" select="$message"/>
	    <xsl:with-param name="name" select="current()"/>
	  </xsl:call-template>
	</xsl:variable>
	<xsl:choose>
	  <xsl:when test="not($usestypes='true')"> 
	    <!-- This is the case; we can be precise -->
	    <xsl:variable name="localName">
	      <xsl:call-template name="resolve-soaprpc-element-localname">
		<xsl:with-param name="msg" select="."/>
	      </xsl:call-template>
	    </xsl:variable>
	    <xsl:variable name="elementType">
	      <xsl:choose>
		<xsl:when test="$localName = '#any'">
		  <xsl:value-of select="$localName"/>			
		</xsl:when>
		<xsl:otherwise>
		  <xsl:value-of select="QName($soapbody/@namespace,      concat('bodyns:',$localName))"/>
		</xsl:otherwise>
	      </xsl:choose>
	    </xsl:variable>
	    <xsl:if test="$localName != '#any'">
	      <xsl:namespace name="bodyns" select="$soapbody/@namespace"/>
	    </xsl:if>
	    <xsl:call-template name="resolve-elementType-attrs">
	      <xsl:with-param name="element" select="$elementType"/>
	      <xsl:with-param name="faultname" select="@name"/>
	    </xsl:call-template>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:call-template name="resolve-elementType-attrs">
	      <xsl:with-param name="element" select="'#any'"/>
	      <xsl:with-param name="faultname" select="@name"/>
	    </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <!-- Is this a simple case? One part defined as an element -->
      <xsl:when test="count($message/w11:part) = 1         and not($message/w11:part/@type)         and $message/w11:part/@element">
	<!-- Simple case when a message has only one part defined as an element -->
	<xsl:variable name="elementType" select="resolve-QName($message/w11:part/@element, $message/w11:part)"/>
	<xsl:namespace name="{prefix-from-QName($elementType)}" select="namespace-uri-from-QName($elementType)"/>
	<xsl:call-template name="resolve-elementType-attrs">
	  <xsl:with-param name="element" select="$elementType"/>
	  <xsl:with-param name="faultname" select="@name"/>
	</xsl:call-template>
      </xsl:when>
      <!-- Is there more than one part? -->
      <xsl:when test="count($message/w11:part) &gt; 1">
	<!-- Case where there's more than one part -->
	<xsl:variable name="httpUrlReplacement">
	  <xsl:for-each select="$bound_operation">
	    <xsl:if test="w11:input[resolve-QName(@message, current())=$message_name]/w11http:urlReplacement or w11:input/w11http:urlReplacement">
	      <xsl:text>y</xsl:text>
	    </xsl:if>
	  </xsl:for-each>
	</xsl:variable>
	<xsl:choose>
	  <!-- Is the message bound to SOAP? -->
	  <xsl:when test="$soapbody">
	    <xsl:choose>
	      <!-- FIXME - BIG FAT WARNING: this is assuming that
	           there's only one binding of the interface In case
	           this isn't the case, we have to hope that the same
	           part is going to be bound to the body, otherwise
	           the assumptions made here are going to be wrong -->
	      <xsl:when test="count($parts) = 1">
		<!-- ... but only one is the body, and is defined as
		     an element -->
		<xsl:variable name="bodypart" select="$message/w11:part[@name = $parts]"/>
		<xsl:if test="not($bodypart/@type)          and $bodypart/@element">
		  <xsl:variable name="elementType" select="resolve-QName($bodypart/@element, $bodypart)"/>
		  <xsl:namespace name="{prefix-from-QName($elementType)}" select="namespace-uri-from-QName($elementType)"/>
		  <xsl:call-template name="resolve-elementType-attrs">
		    <xsl:with-param name="element" select="$elementType"/>
		    <xsl:with-param name="faultname" select="@name"/>
		  </xsl:call-template>
		</xsl:if>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:call-template name="resolve-elementType-attrs">
		  <xsl:with-param name="element" select="'#any'"/>
		  <xsl:with-param name="faultname" select="@name"/>
		</xsl:call-template>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:when>
	  <!-- Is the message bound to HTTP with URL replacement? -->
	  <xsl:when test="contains($httpUrlReplacement, 'y')">
	    <xsl:namespace name="convertns" select="concat(/w11:definitions/@targetNamespace, 'GEN')"/>
	    <xsl:call-template name="resolve-elementType-attrs">
	      <xsl:with-param name="element" select="concat('convertns:', ../@name)"/>
	      <xsl:with-param name="faultname" select="@name"/>
	    </xsl:call-template>
	  </xsl:when>
	  <!-- No, the message is not bound to SOAP nor to HTTP, we don't make any assumptions -->
	  <xsl:otherwise>
	    <xsl:call-template name="resolve-elementType-attrs">
	      <xsl:with-param name="element" select="'#any'"/>
	      <xsl:with-param name="faultname" select="@name"/>
	    </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="resolve-elementType-attrs">
	  <xsl:with-param name="element" select="'#any'"/>
	  <xsl:with-param name="faultname" select="@name"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="http-serialization">
    <xsl:param name="binding-msg-ref"/>
    <xsl:param name="attrib"/>
    <xsl:variable name="mime" select="$binding-msg-ref/w11mime:content"/>
    <xsl:if test="count($mime) = 1 and $mime/@type">
      <xsl:attribute name="{$attrib}">
	<xsl:value-of select="$mime/@type"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="count($mime) &gt; 1">
      <xsl:attribute name="{$attrib}">*/*</xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template match="w11:binding">
    <binding name="{@name}" interface="{@type}">
      <xsl:variable name="qname" select="resolve-QName(@type, .)"/>
      <xsl:namespace name="{prefix-from-QName($qname)}" select="namespace-uri-from-QName($qname)"/>
      <xsl:if test="w11soap:binding">
	<xsl:attribute name="type">http://www.w3.org/ns/wsdl/soap</xsl:attribute>
	<xsl:attribute name="version" namespace="http://www.w3.org/ns/wsdl/soap">1.1</xsl:attribute>
	<xsl:attribute name="protocol" namespace="http://www.w3.org/ns/wsdl/soap">
	  <xsl:choose>
	    <xsl:when test="w11soap:binding/@transport = &quot;http://schemas.xmlsoap.org/soap/http&quot;">
	      <xsl:text>http://www.w3.org/2006/01/soap11/bindings/HTTP/</xsl:text>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:value-of select="w11soap:binding/@transport"/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="w11http:binding">
	<xsl:attribute name="type">http://www.w3.org/ns/wsdl/http</xsl:attribute>
	<xsl:attribute name="methodDefault" namespace="http://www.w3.org/ns/wsdl/http">
	  <xsl:value-of select="w11http:binding/@verb"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="/w11:definitions[@targetNamespace = namespace-uri-from-QName($qname)]         /w11:portType[@name = local-name-from-QName($qname)]/w11:operation/w11:fault" mode="binding"/>
      <xsl:apply-templates select="*[not(local-name()=&quot;binding&quot;        and (namespace-uri() = &quot;http://schemas.xmlsoap.org/wsdl/soap/&quot;        or namespace-uri() = &quot;http://schemas.xmlsoap.org/wsdl/http/&quot;))]"/>
    </binding>
  </xsl:template>

  <xsl:template match="w11:binding/w11:operation">
    <xsl:variable name="prefix">
      <xsl:value-of select="prefix-from-QName($qname)"/>
    </xsl:variable>
		  
    <operation ref="{$prefix}:{@name}">
      <xsl:namespace name="{$prefix}" select="/w11:definitions/@targetNamespace"/>
      <!-- SOAP Binding -->
      <xsl:variable name="action" select="w11soap:operation/@soapAction"/>
      <xsl:if test="$action != &quot;&quot;">
	<!--
	    @@@ Unsure about this test:
	    http://lists.w3.org/Archives/Public/public-ws-desc-comments/2006Feb/0000.html
	-->
	<xsl:attribute name="soapAction" namespace="http://www.w3.org/ns/wsdl/soap">
	  <xsl:value-of select="$action"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="../w11soap:binding">
	<xsl:if test="w11:input/w11soap:header or w11:output/w11soap:header">
	  <xsl:apply-templates select="*" mode="binding"/>
	</xsl:if>
      </xsl:if>
      <!-- HTTP Binding -->
      <xsl:if test="../w11http:binding">
	<xsl:call-template name="http-serialization">
	  <xsl:with-param name="binding-msg-ref" select="w11:input"/>
	  <xsl:with-param name="attrib" select="'inputSerialization'"/>
	</xsl:call-template>
	<xsl:call-template name="http-serialization">
	  <xsl:with-param name="binding-msg-ref" select="w11:output"/>
	  <xsl:with-param name="attrib" select="'outputSerialization'"/>
	</xsl:call-template>
      </xsl:if>
      <xsl:if test="w11http:operation/@location">
	<xsl:choose>
	  <xsl:when test="w11:input/w11http:urlReplacement">
	    <xsl:attribute name="location" namespace="http://www.w3.org/ns/wsdl/http">
	      <xsl:value-of select="translate(w11http:operation/@location, '()', '{}')"/>
	    </xsl:attribute>
	    <xsl:attribute name="ignoreUncited" namespace="http://www.w3.org/ns/wsdl/http">
	      <xsl:text>true</xsl:text>
	    </xsl:attribute>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:attribute name="location" namespace="http://www.w3.org/ns/wsdl/http">
	      <xsl:value-of select="w11http:operation/@location"/>
	    </xsl:attribute>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:if>
    </operation>
  </xsl:template>

  <xsl:template match="w11:input|w11:output" mode="binding">
    <!-- We're not specifying @messageLabel here because it is not needed for the MEPs 
    that we handle -->
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/ns/wsdl">
      <xsl:variable name="messageName" select="local-name-from-QName(resolve-QName(current()/w11soap:header/@message, current()/w11soap:header))"/>
      <xsl:variable name="partName" select="current()/w11soap:header/@part"/>
      <xsl:variable name="elementName" select="//w11:message[@name=$messageName]/w11:part[@name=$partName]/@element"/>
      <!-- FIXME: Not handling types -->
      <xsl:if test="$elementName">
	<wsoap:header required="true">
	  <xsl:variable name="element" select="resolve-QName($elementName, //w11:message[@name=$messageName]/w11:part[@name=$partName])"/>
	  <xsl:namespace name="{prefix-from-QName($element)}" select="namespace-uri-from-QName($element)"/>
	  <xsl:attribute name="element">
	    <xsl:value-of select="$element"/>
	  </xsl:attribute>
	</wsoap:header>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <xsl:template match="w11:service">
    <service name="{@name}">
      <xsl:variable name="binding_qname" select="resolve-QName(w11:port[1]/@binding, w11:port[1])"/>
      <xsl:variable name="binding" select="/w11:definitions[@targetNamespace = namespace-uri-from-QName($binding_qname)]         /w11:binding[@name = local-name-from-QName($binding_qname)]"/>
      <xsl:variable name="interface" select="resolve-QName($binding/@type, $binding)"/>
      <xsl:attribute name="interface">
	<xsl:value-of select="$interface"/>
      </xsl:attribute>
      <xsl:namespace name="{prefix-from-QName($interface)}" select="namespace-uri-from-QName($interface)"/>
      <xsl:apply-templates select="*"/>
    </service>
  </xsl:template>

  <xsl:template match="w11:port">
    <endpoint name="{@name}" binding="{@binding}">
      <xsl:variable name="qname" select="resolve-QName(@binding, .)"/>
      <xsl:namespace name="{prefix-from-QName($qname)}" select="namespace-uri-from-QName($qname)"/>
      <xsl:if test="w11soap:address">
	<xsl:attribute name="address">
	  <xsl:value-of select="w11soap:address/@location"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="w11http:address">
	<xsl:attribute name="address">
	  <xsl:value-of select="w11http:address/@location"/>
	</xsl:attribute>
      </xsl:if>
    </endpoint>
  </xsl:template>

  <xsl:template match="w11:documentation">
    <documentation>
      <xsl:apply-templates select="*|@*|text()"/>
    </documentation>
  </xsl:template>

  <xsl:template match="*|@*|text()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>

</xsl:transform>