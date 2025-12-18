// app/javascript/controllers/index.js

import { application } from "controllers/application"

// 手動でインポートして登録する
import HelloController from "controllers/hello_controller"
application.register("hello", HelloController)

import MapController from "controllers/map_controller"
application.register("map", MapController)

import SortableController from "controllers/sortable_controller"
application.register("sortable", SortableController)

import GeocodingController from "controllers/geocoding_controller"
application.register("geocoding", GeocodingController)

import ScrollController from "controllers/scroll_controller"
application.register("scroll", ScrollController)