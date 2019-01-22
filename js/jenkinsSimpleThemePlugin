tagLine="This is the Test Server"
document.write("<h1 id='custom-banner' style=color:red;text-align:center>THIS IS THE TEST SERVER</h1>");
<!--window.onload=function(){-->
<!--document.onreadystatechange=function(){-->
  <!--ddTagLine();-->
<!--}-->
<!--ddTagLine();-->
function addTagLine(){
  var tagElement=document.createElement('h1');
  tagElement.innerText=tagLine;
  addToDiv(tagElement);
}
function addToDiv(tagElement){
  var innerDiv=document.createElement('div');
  innerDiv.appendChild(tagElement);
  innerDiv.classList.add("customBanner");
<!--  addAfterLogo(innerDiv);-->
<!--  addToPageHead(innerDiv);-->
<!--  addToPageBody(innerDiv)-->
  addBeforeSidePanel(innerDiv);
}
function addAfterLogo(innerDiv){
  var logoRef=document.getElementById("jenkins-home-link");
  var logoDiv=logoRef.parentNode;
  var header=document.getElementById("header");
  header.insertBefore(innerDiv,logoDiv.nextSibling);
}
function addToPageHead(innerDiv){
  var pageHead=document.getElementById("page-head");
  pageHead.appendChild(innerDiv);
}
function addToPageBody(innerDiv){
  var pageBody=document.getElementById("page-body");
  pageBody.prepend(innerDiv);
}
function addBeforeSidePanel(innerDiv){
  var sidePanel=document.getElementById("side-panel");
  sidePanel.parentNode.insertBefore(innerDiv,sidePanel);
}
