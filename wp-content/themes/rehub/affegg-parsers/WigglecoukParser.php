<?php

namespace Keywordrush\AffiliateEgg;
/*
 Name: Wiggle.co.uk
 URI: http://www.wiggle.co.uk
 Icon: http://www.google.com/s2/favicons?domain=wiggle.co.uk
 CPA: 
 */
/**
 * WigglecoukParser class file
 *
 * @author keywordrush.com <support@keywordrush.com>
 * @link http://www.keywordrush.com/
 * @copyright Copyright &copy; 2014 keywordrush.com
 */
class WigglecoukParser extends ShopParser {

    protected $charset = 'utf-8';
    protected $currency = 'USD';    
    
    public function parseCatalog($max)
    {
 	return array_slice($this->xpathArray(".//div[@id='search-results']//div[contains(@class,'js-result-list-item')]//a[@data-ga-action='Product Title']/@href"), 0, $max);
    }

    public function parseTitle()
    {
        return $this->xpathScalar(".//h1[@itemprop='name']/text()");
        
    }

    public function parseDescription()
    {
        $res = $this->xpathArray(".//div[@itemprop='description']");
        return sanitize_text_field(implode(' ', $res));
    }

    public function parsePrice() {
       $res = (float) preg_replace('/[^0-9\.]/', '', $this->xpathScalar(".//div[@id='itemtop']//span[@itemprop='price']"));
       return $res;
           
    }

    public function parseOldPrice() {
       $res = (float) preg_replace('/[^0-9\.]/', '', $this->xpathScalar(".//div[@class='bem-product-price--pdp']/span[@class='bem-product-price__list']"));
       return $res;
    }

    public function parseManufacturer()
    {
        return $this->xpathScalar(".//div[@id='itemtop']//span[@itemprop='manufacturer']");
    }

    public function parseImg()
    {
        $imagenormalurl = $this->xpathScalar(".//div[@id='mainImageWrapper']//img[@itemprop='image']/@src");
        //$imagenormalurl = str_replace('?w=430&h=430&a=7', '', $imagenormalurl);
        $imagenormalurl = str_replace('http:', '', $imagenormalurl);
        $imagenormalurl = str_replace('https:', '', $imagenormalurl);
        $imagenormalurl = 'https:'.$imagenormalurl.'.jpg';

        return $imagenormalurl;
    }

    public function parseImgLarge()
    {
        $imageurl = $this->xpathScalar(".//div[@id='mainImageWrapper']//img[@itemprop='image']/@src");
        $imageurl = str_replace('?w=430&h=430&a=7', '', $imageurl);
        $imageurl = str_replace('http:', '', $imageurl);
        $imageurl = str_replace('https:', '', $imageurl);
        $imageurl = 'https:'.$imageurl;        
        return $imageurl;     
    }

    public function parseExtra()
    {
        $extra = array();

        $extra['features'] = array();

        $names = $this->xpathArray(".//div[@id='tabDescription']//tr[@class='bem-table__row']/th");
        $values = $this->xpathArray(".//div[@id='tabDescription']//tr[@class='bem-table__row']/td");
        $feature = array();
        for ($i = 0; $i < count($names); $i++) {
            if (!empty($values[$i])) {
                $feature['name'] = str_replace(":", "", $names[$i]);
                $feature['value'] = $values[$i];
                $extra['features'][] = $feature;
            }
        }          
        
        $extra['images'] = array();
        $results = $this->xpathArray(".//ul[@id='gallery']/li//img/@src");

        foreach ($results as $i => $res) {
            if ($i == 0)
                continue;
            if ($res) {
                $res = str_replace('w=73&h=73', 'w=430&h=430', $res);
                $extra['images'][] = $res;
            }
        }
        return $extra;
    }

    public function isInStock()
    {
        $res = $this->xpath->evaluate("boolean(.//div[@id='productAvailabilityMessage'][contains(@class,'out-of-stock')])");
        return ($res) ? false : true;          
    }

}