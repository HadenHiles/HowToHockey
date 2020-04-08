<?php $search_text = (rehub_option("rehub_search_text")) ? rehub_option("rehub_search_text") : __("Search", "rehub_framework"); ?>
<form  role="search" method="get" class="search-form" action="<?php echo home_url( '/' ); ?>">
  <input type="text" name="s" placeholder="<?php echo $search_text ;?>">
  <button type="submit" class="btnsearch"><i class="fa fa-search"></i></button>
</form>