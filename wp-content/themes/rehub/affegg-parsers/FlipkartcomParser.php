<?php

namespace Keywordrush\AffiliateEgg;
/*
 Name: Flipkart.com
 URI: http://www.flipkart.com
 Icon: http://www.google.com/s2/favicons?domain=flipkart.com
 CPA: 
 */

/**
 * FlipkartcomParser class file
 *
 * @author keywordrush.com <support@keywordrush.com>
 * @link http://www.keywordrush.com/
 * @copyright Copyright &copy; 2014 keywordrush.com
 */
class FlipkartcomParser extends ShopParser {

    protected $charset = 'utf-8';
    protected $currency = 'INR';

    public function parseCatalog($max) {
        $urls = array_slice($this->xpathArray(".//div[contains(@class,'pu-title')]/a/@href"), 0, $max);
        foreach ($urls as $i => $url)
            {
                if (!preg_match('/^http:\/\//', $url))
                    $urls[$i] = 'http://www.flipkart.com' . $url;
            }
        return $urls;
    }

    public function parseTitle() {
        return $this->xpathScalar(".//h1[@class='title']");
    }

    public function parseDescription() {
           $descr = '';
           $results = $this->xpathArray(".//ul[@class='keyFeaturesList']/li"); 
           $descr = implode(";\n", $results);              
        return $descr;
    }

    public function parsePrice() {
        return (float) preg_replace('/[^0-9]/', '', $this->xpathScalar(".//div[contains(@class,'price-wrap')]//span[contains(@class,'selling-price')]"));
    }

    public function parseOldPrice() {
        return (float) preg_replace('/[^0-9]/', '', $this->xpathScalar(".//div[contains(@class,'price-wrap')]//span[@class='price']"));
    }

    public function parseManufacturer() {
        return $this->xpathScalar(".//div[contains(@class,'productSpecs')]//td[@class='specsKey'][. = 'Brand']/following-sibling::td[1]");
    }

    public function parseImg() {
        return $this->xpathScalar(".//div[@class='mainImage']//img[1]/@data-src");
    }

    public function parseImgLarge() {
        return $this->xpathScalar(".//div[@class='mainImage']//img[1]/@data-zoomimage");
    }

    public function parseExtra() {
        $extra = array();

        $extra['features'] = array();

        $names = $this->xpathArray(".//div[contains(@class,'productSpecs')]//td[@class='specsKey']");
        $values = $this->xpathArray(".//div[contains(@class,'productSpecs')]//td[@class='specsValue']");
        $feature = array();
        for ($i = 0; $i < count($names); $i++) {
            if (!empty($values[$i]) && $names[$i] != 'Condition:' && $names[$i] != 'Brand') {
                $feature['name'] = str_replace(":", "", $names[$i]);
                $feature['value'] = $values[$i];
                $extra['features'][] = $feature;
            }
        }            
        
        $extra['images'] = array();
        $results = $this->xpathArray(".//div[@class='mainImage']//img[position() >=2]/@data-zoomimage");

        foreach ($results as $i => $res) {
            if ($i == 0)
                continue;
            if ($res) {
                $extra['images'][] = $res;
            }
        }
        return $extra;
    }

    public function isInStock() {
        {
            $res = $this->xpath->evaluate("boolean(.//div[@class='out-of-stock-status'])");
            return ($res) ? false : true;        
        }
    }

}
