<?php

namespace Keywordrush\AffiliateEgg;
/*
 Name: Saturn.de
 URI: http://www.saturn.de
 Icon: http://www.google.com/s2/favicons?domain=saturn.de
 CPA: 
 */

/**
 * SaturndeParser class file
 *
 * @author keywordrush.com <support@keywordrush.com>
 * @link http://www.keywordrush.com/
 * @copyright Copyright &copy; 2014 keywordrush.com
 */
class SaturndeParser extends ShopParser {

    protected $charset = 'utf-8';
    protected $currency = 'EUR';

    public function parseCatalog($max) {
        $urls = array_slice($this->xpathArray(".//div[@class='product-wrapper']//h2/a/@href"), 0, $max);
        foreach ($urls as $i => $url)
            {
                if (!preg_match('/^http:\/\//', $url))
                    $urls[$i] = 'http://www.saturn.de' . $url;
            }
        return $urls;
    }

    public function parseTitle() {
        return $this->xpathScalar(".//h1[@itemprop='name']");
    }

    public function parseDescription() {
           $descr = '';
           $results = $this->xpathScalar(".//article[@id='produktbeschreibung']/p"); 
           $descr = sanitize_text_field($results);              
        return $descr;
    }

    public function parsePrice() {
        return (float) preg_replace('/[^0-9.]/', '', $this->xpathScalar(".//div[@class='price-details']/meta[@itemprop='price']/@content"));
    }

    public function parseOldPrice() {
        return '';
    }

    public function parseManufacturer() {
        return $this->xpathScalar(".//div[@class='price-details']/meta[@itemprop='brand']/@content");
    }

    public function parseImg() {
        $imageurl = $this->xpathScalar(".//meta[@property='og:image']/@content");
            $imageurl = $imageurl.'.jpg';
        return $imageurl;
    }

    public function parseImgLarge() {
        $imageurlbig = $this->xpathScalar(".//meta[@property='og:image']/@content");
            $imageurlbig = $imageurlbig.'.jpg';
        return $imageurlbig;        
    }

    public function parseExtra() {
        $extra = array();

        $extra['features'] = array();

        $names = $this->xpathArray(".//div[@id='features']//dl[@class='specification']/dt");
        $values = $this->xpathArray(".//div[@id='features']//dl[@class='specification']/dd");
        $feature = array();
        for ($i = 0; $i < count($names); $i++) {
            if (!empty($values[$i])) {
                $feature['name'] = str_replace(":", "", $names[$i]);
                $feature['value'] = $values[$i];
                $extra['features'][] = $feature;
            }
        }            
        
        $extra['images'] = array();
        $results = $this->xpathArray(".//aside[@id='product-sidebar']/ul[@class='thumbs']/li[position() >=2]/a/@data-magnifier");

        foreach ($results as $i => $res) {
            if ($i == 0)
                continue;
            if ($res) {
                $extra['images'][] = $res;
            }
        }
        return $extra;
    }

    public function isInStock() 
        {
            return true;
        }
}
