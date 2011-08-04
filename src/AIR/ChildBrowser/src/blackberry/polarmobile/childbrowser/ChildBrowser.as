/**
 * Author: Shane Jonas
 * Child Browser Implementation for the PlayBook
 */

package blackberry.polarmobile.childbrowser
{
    // flash
    import flash.geom.Rectangle;
    import flash.display.Stage;
    import flash.events.MouseEvent;
    import flash.display.Sprite;
    import flash.events.StageOrientationEvent;
    import flash.display.Bitmap;
    import flash.utils.setTimeout;

    import caurina.transitions.Tweener;

    // qnx 
    import qnx.media.QNXStageWebView;
    import qnx.ui.buttons.IconButton;
    import qnx.ui.skins.buttons.OutlineButtonSkinBlack;

    // webworks
    import webworks.extension.DefaultExtension;


    public class ChildBrowser extends DefaultExtension
    {
        private var childWebView:QNXStageWebView = null;
        private var closeButton:IconButton;
        private var refreshButton:IconButton;
        private var bgshape:Sprite;
        private var loading_bg_shape:Sprite;
        private var browserHeight;
        private var isVisible:Boolean;

        //icons
        [Embed(source="assets/close.png")] 
        public static var Close:Class;
        [Embed(source="assets/refresh.png")] 
        public static var Refresh:Class;
        [Embed(source="assets/ajax-spinner-black-bg.gif")] 
        public static var Spinner:Class;

        public function ChildBrowser() 
        {
            super();
            this.isVisible = false
        }

        override public function getFeatureList():Array 
        {
            return new Array ("blackberry.polarmobile.childbrowser");
        }

        private function initBG(callback)
        {
            bgshape = new Sprite();
            bgshape.graphics.beginFill(0x323232);
            bgshape.graphics.drawRect(0,0,webView.stage.stageWidth, webView.stage.stageHeight);
            bgshape.y = webView.stage.stageHeight
            webView.stage.addChildAt(bgshape, 0);

            Tweener.addTween(bgshape, {
              y: 0,
              time: 1,
              transition: 'easeOutExpo',
              onComplete: callback
            });
        }

        public function clearCookies()
        {
          //if we dont have a webview, make one and put it in the background
          if (childWebView == null) 
          {
              childWebView = new QNXStageWebView("ChildBrowser");
              childWebView.stage = webView.stage;
              childWebView.viewPort = new Rectangle(0,50,webView.stage.stageWidth,browserHeight);
              childWebView.zOrder = -1;
          }
          //clear the webviews cookies
          childWebView.clearCookies();
          //set to about blank
          this.clearWindow();
        }

        public function loadURL(url:String)
        {
            webView.zOrder = -1;
            var self = this
            browserHeight = webView.stage.stageHeight - 50;

            //only ever create one web view
            function createBrowser(){
              if (childWebView == null) 
              {
                  childWebView = new QNXStageWebView("ChildBrowser");
                  childWebView.stage = webView.stage;
                  childWebView.viewPort = new Rectangle(0,50,webView.stage.stageWidth,browserHeight);
              }

              //if its not visible.. i want to see it
              if (!self.getVisible())
              {
                  self.setVisible(true)
              }

              //load this url
              childWebView.loadURL(url);

              //build buttons
              self.initUI();

              // events
              webView.stage.addEventListener(StageOrientationEvent.ORIENTATION_CHANGE, onOrientationChange);
            }

            this.initBG(createBrowser);
        }

        private function onOrientationChange(event:StageOrientationEvent)
        {
            var self = this
            this.removeUI();
            this.initBG(function(){
              self.initUI()
            });
            childWebView.viewPort = new Rectangle(0,50,webView.stage.stageWidth,browserHeight);
        }

        private function clearWindow()
        {
            childWebView.loadURL("about:blank");
        }

        public function getLocation():String
        {
            return childWebView.location;
        }

        public function forward()
        {
            childWebView.historyForward();
        }

        public function back()
        {
            childWebView.historyBack();
        }

        public function refresh()
        {
            childWebView.reload();
        }

        public function close()
        {
          // the `dispose` method does not work when running inside of webworks,
          // as it closes then main `webView` instance. as a temp. work-around,
          // we hide the child
          this.setVisible(false)
          this.clearWindow();
        }

        public function closeCLICK(e:MouseEvent)
        {
          this.close();
          this.removeUI();
        }

        public function refreshCLICK(e:MouseEvent)
        {
          this.refresh();
        }

        private function removeUI()
        {
          removeChild(bgshape);
          removeChild(closeButton);
          removeChild(refreshButton)
        }

        //close button
        private function addClose()
        {
          closeButton = new IconButton();
          closeButton.setIcon(new Close());
          closeButton.setSize(266, 50);
          closeButton.setPosition(-5, 0);
          closeButton.setSkin(new OutlineButtonSkinBlack());
          closeButton.addEventListener(MouseEvent.CLICK, closeCLICK);
          addChild(closeButton);
        }

        //refresh button
        private function addRefresh()
        {
          refreshButton = new IconButton();
          refreshButton.setIcon(new Refresh());
          refreshButton.setSize(266, 50);
          refreshButton.setPosition(256, 0);
          refreshButton.setSkin(new OutlineButtonSkinBlack())
          refreshButton.addEventListener(MouseEvent.CLICK, refreshCLICK);
          addChild(refreshButton);
        }

        // UI Buttons
        private function initUI()
        {
          this.addClose();
          this.addRefresh();
        }

        public function getVisible():Boolean
        {
          return this.isVisible; 
        }

        private function setVisible(arg:Boolean) 
        {
          this.isVisible = arg
          if (arg == true){
            webView.zOrder = -1;
            childWebView.zOrder = 1;
          } else {
            webView.zOrder = 1;
            childWebView.zOrder = -1;
          }
        }

        private function addLoadingScreen()
        {
          childWebView.zOrder = -1;

          loading_bg_shape = new Sprite();
          //dark gray for now
          loading_bg_shape.graphics.beginFill(0x323232);
          //semi transparent
          loading_bg_shape.alpha = 0.5;
          loading_bg_shape.graphics.drawRect(0,0,webView.stage.stageWidth, webView.stage.stageHeight);
          addChild(loading_bg_shape);

          var loadingSpinner:Bitmap = new Spinner();
          loadingSpinner.x = webView.stage.stageWidth / 2;
          loadingSpinner.y = webView.stage.stageHeight / 2;

          addChild(loadingSpinner);

        }

        // our own addChild implementation
        // maps back to stage of WebWorkAppTemplate.as
        private function addChild(obj)
        {
          webView.stage.addChild(obj);
          //always set added obj's to top
          webView.stage.setChildIndex(obj, webView.stage.numChildren -1);
        }

        private function removeChild(obj)
        {
          webView.stage.removeChild(obj);
        }

    }
}
