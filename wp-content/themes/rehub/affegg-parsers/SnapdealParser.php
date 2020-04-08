<?php

namespace Keywordrush\AffiliateEgg;

/*
  Name: Snapdeal.com
  URI: http://www.snapdeal.com
  Icon: http://www.google.com/s2/favicons?domain=snapdeal.com
  CPA:
 */

/**
 * SnapdealParser class file
 *
 * @author keywordrush.com <support@keywordrush.com>
 * @link http://www.keywordrush.com/
 * @copyright Copyright &copy; 2015 keywordrush.com
 */
class SnapdealParser extends ShopParser {

    protected $charset = 'utf-8';
    protected $currency = 'INR';

    public function parseCatalog($max)
    {
        return array_slice($this->xpathArray(".//div[@class='productWrapper']//div[@class='product-title']/a/@href"), 0, $max);
    }

    public function parseTitle()
    {
        return $this->xpathScalar(".//meta[@property='og:title']/@content");
    }

    public function parseDescription()
    {
        return $this->xpathScalar(".//section[@id='productSpecs']//div[@class='detailssubbox'][@itemprop='description']");
    }

    public function parsePrice()
    {
        $price = preg_replace('/[^0-9\.]/', '', $this->xpathScalar(".//*[@id='buyPriceBox']//span[@itemprop='price']"));
        //$price = str_replace(',', '.', $price);
        return (float) $price;
    }

    public function parseOldPrice()
    {
        $price = preg_replace('/[^0-9\.]/', '', $this->xpathScalar(".//*[@id='buyPriceBox']//s/span"));
        //$price = str_replace(',', '.', $price);
        return (float) $price;
    }

    public function parseManufacturer()
    {
        return '';
    }

    public function parseImg()
    {

        return $this->xpathScalar(".//*[@id='bx-slider-left-image-panel']//img[@itemprop='image']/@src");
    }

    public function parseImgLarge()
    {
        return $this->xpathScalar(".//*[@id='bx-slider-left-image-panel']//img[@itemprop='image']/@bigsrc");
    }

    public function parseExtra()
    {
        $extra = array();
        $extra['features'] = array();
        $names = $this->xpathArray(".//div[@class='spec-body']//tr/td[@width]");
        $values = $this->xpathArray(".//div[@class='spec-body']//tr/td[2]");
        $feature = array();
        for ($i = 0; $i < count($names); $i++) {
            if (!empty($values[$i]) && $names[$i] != '1' && $names[$i] != '2' && $names[$i] != '3' && $names[$i] != '4') {
                $feature['name'] = $names[$i];
                $feature['value'] = $values[$i];
                $extra['features'][] = $feature;
            }
        }
        return $extra;
    }

    public function isInStock()
    {
        return true;
    }

}
