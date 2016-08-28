How to Setup Web To Lead Form to Capture GAUID?

Open following JSBin:
  goo.gl/w1HVTg OR http://jsbin.com/luxekifuta/edit?html,output

a) Clone the Bin.

b) Replace "UA-99999999-1" with your GA Tracking ID in the following line:
  ga('create', 'UA-99999999-1', 'auto');

c) Copy and Paste the "Web to Lead" form in the indicated area:
  <!-- PASTE YOUR FORM HERE -->

d) Copy the ID of the GAUID input element and replace it in the "captureGAUID" function:

  function captureGAUID(){
    jQuery("#00N2800000E97IZ").val(Cookies.get('_ga').substr(6));
  }

e) include the "onclick" attribute below in the submit element
  <input type="submit" onclick="captureGAUID();" name="submit">
