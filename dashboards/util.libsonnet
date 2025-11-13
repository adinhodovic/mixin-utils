local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local annotation = g.dashboard.annotation;

local variable = dashboard.variable;
local prometheus = g.query.prometheus;

local stat = g.panel.stat;
local timeSeries = g.panel.timeSeries;
local table = g.panel.table;
local pieChart = g.panel.pieChart;
local heatmap = g.panel.heatmap;
local text = g.panel.text;

// Stat
local stOptions = stat.options;
local stStandardOptions = stat.standardOptions;
local stQueryOptions = stat.queryOptions;
local stPanelOptions = stat.panelOptions;

// PieChart
local pcOptions = pieChart.options;
local pcStandardOptions = pieChart.standardOptions;
local pcPanelOptions = pieChart.panelOptions;
local pcQueryOptions = pieChart.queryOptions;
local pcLegend = pcOptions.legend;

// TimeSeries
local tsOptions = timeSeries.options;
local tsStandardOptions = timeSeries.standardOptions;
local tsPanelOptions = timeSeries.panelOptions;
local tsQueryOptions = timeSeries.queryOptions;
local tsFieldConfig = timeSeries.fieldConfig;
local tsCustom = tsFieldConfig.defaults.custom;
local tsLegend = tsOptions.legend;

// Table
local tbOptions = table.options;
local tbStandardOptions = table.standardOptions;
local tbQueryOptions = table.queryOptions;

// Heatmap
local hmOptions = heatmap.options;
local hmPanelOptions = heatmap.panelOptions;
local hmQueryOptions = heatmap.queryOptions;

// Textpanel
local textOptions = text.options;
local textPanelOptions = text.panelOptions;

{
  // Bypasses grafana.com/dashboards validator
  bypassDashboardValidation: {
    __inputs: [],
    __requires: [],
  },

  dashboardDescriptionLink(name, link): 'The dashboards were generated using %s. %s. Open issues and create feature requests in the repository.' % [name, link],

  statPanel(
    title,
    unit,
    query,
    instant=false,
    description=null,
    graphMode='area',
    showPercentChange=false,
    decimals=null,
    percentChangeColorMode='standard',
    steps=[
      stStandardOptions.threshold.step.withValue(0) +
      stStandardOptions.threshold.step.withColor('green'),
    ],
    mappings=[]
  )::
    stat.new(title) +
    (
      if description != null then
        stPanelOptions.withDescription(description)
      else {}
    ) +
    stQueryOptions.withTargets([
      prometheus.new('${datasource}', query) +
      (
        if instant then
          prometheus.withInstant(instant)
        else {}
      ),
    ]) +
    variable.query.withDatasource('prometheus', '$datasource') +
    stOptions.withGraphMode(graphMode) +
    stOptions.withShowPercentChange(showPercentChange) +
    stOptions.withPercentChangeColorMode(percentChangeColorMode) +
    (
      if decimals != null then
        stStandardOptions.withDecimals(decimals)
      else {}
    ) +
    stStandardOptions.withUnit(unit) +
    stStandardOptions.thresholds.withSteps(steps) +
    stStandardOptions.withMappings(
      mappings
    ),


  pieChartPanel(title, unit, query, legend='', description='', labels=['percent'], values=['percent'], overrides=[])::
    pieChart.new(
      title,
    ) +
    pieChart.new(title) +
    (
      if description != '' then
        pcPanelOptions.withDescription(description)
      else {}
    ) +
    variable.query.withDatasource('prometheus', '$datasource') +
    pcQueryOptions.withTargets(
      if std.isArray(query) then
        [
          prometheus.new(
            '$datasource',
            q.expr,
          ) +
          prometheus.withLegendFormat(
            q.legend
          ) +
          prometheus.withInstant(true)
          for q in query
        ] else
        prometheus.new(
          '$datasource',
          query,
        ) +
        prometheus.withLegendFormat(
          legend
        ) +
        prometheus.withInstant(true)
    ) +
    pcStandardOptions.withUnit(unit) +
    pcOptions.tooltip.withMode('multi') +
    pcOptions.tooltip.withSort('desc') +
    pcOptions.withDisplayLabels(labels) +
    pcLegend.withShowLegend(true) +
    pcLegend.withDisplayMode('table') +
    pcLegend.withPlacement('right') +
    pcLegend.withValues(values) +
    pcStandardOptions.withOverrides(overrides),

  timeSeriesPanel(title, unit, query, legend='', calcs=['mean', 'max'], stack=null, description=null, exemplar=false)::
    timeSeries.new(title) +
    (
      if description != null then
        tsPanelOptions.withDescription(description)
      else {}
    ) +
    variable.query.withDatasource('prometheus', '$datasource') +
    tsQueryOptions.withTargets(
      if std.isArray(query) then
        [
          prometheus.new(
            '$datasource',
            q.expr,
          ) +
          prometheus.withLegendFormat(
            q.legend
          ) +
          prometheus.withExemplar(
            // allows us to override exemplar per query if needed
            std.get(q, 'exemplar', default=exemplar)
          ) +
          (
            if std.get(q, 'interval', default='') != '' then
              prometheus.withInterval(q.interval)
            else {}
          )
          for q in query
        ] else
        prometheus.new(
          '$datasource',
          query,
        ) +
        prometheus.withLegendFormat(
          legend
        ) +
        prometheus.withExemplar(exemplar)
    ) +
    tsStandardOptions.withUnit(unit) +
    tsOptions.tooltip.withMode('multi') +
    tsOptions.tooltip.withSort('desc') +
    tsLegend.withShowLegend() +
    tsLegend.withDisplayMode('table') +
    tsLegend.withPlacement('right') +
    tsLegend.withCalcs(calcs) +
    tsLegend.withSortBy('Mean') +
    tsLegend.withSortDesc(true) +
    tsCustom.withFillOpacity(10) +
    (
      if stack == 'normal' then
        tsCustom.withAxisSoftMin(0) +
        tsCustom.withFillOpacity(100) +
        tsCustom.stacking.withMode(stack) +
        tsCustom.withLineWidth(1)
      else if stack == 'percent' then
        tsCustom.withFillOpacity(100) +
        tsCustom.stacking.withMode(stack) +
        tsCustom.withLineWidth(1)
      else {}
    ),

  tablePanel(title, unit, query, description=null, sortBy=null, transformations=[], overrides=[], steps=[])::
    table.new(title) +
    (
      if description != null then
        tsPanelOptions.withDescription(description)
      else {}
    ) +
    tbStandardOptions.withUnit(unit) +
    tbOptions.footer.withEnablePagination(true) +
    variable.query.withDatasource('prometheus', '$datasource') +
    tsQueryOptions.withTargets(
      if std.isArray(query) then
        [
          prometheus.new(
            '$datasource',
            q.expr,
          ) +
          prometheus.withFormat('table') +
          prometheus.withInstant(true)
          for q in query
        ] else
        prometheus.new(
          '$datasource',
          query,
        ) +
        prometheus.withFormat('table') +
        prometheus.withInstant(true)
    ) +
    (
      if sortBy != null then
        tbOptions.withSortBy(
          tbOptions.sortBy.withDisplayName(sortBy.name) +
          tbOptions.sortBy.withDesc(sortBy.desc)
        ) else {}
    ) +
    tbQueryOptions.withTransformations(transformations) +
    tbStandardOptions.withOverrides(overrides) +
    tbStandardOptions.thresholds.withSteps(steps),

  heatmapPanel(title, unit, query, description=null)::
    heatmap.new(title) +
    (
      if description != null then
        hmPanelOptions.withDescription(description)
      else {}
    ) +
    variable.query.withDatasource('prometheus', '$datasource') +
    hmQueryOptions.withTargets(
      if std.isArray(query) then
        [
          prometheus.new(
            '$datasource',
            q.expr,
          ) +
          prometheus.withLegendFormat(
            q.legend
          )
          for q in query
        ] else
        prometheus.new(
          '$datasource',
          query,
        )
    ) +
    hmOptions.withCalculate(true) +
    hmOptions.yAxis.withUnit(unit),

  textPanel(title, content, description=null, mode='markdown')::
    text.new(title) +
    (
      if description != null then
        textPanelOptions.withDescription(description)
      else {}
    ) +
    textOptions.withMode(mode) +
    textOptions.withContent(content),

  annotations(config, filters)::
    local customAnnotation =
      annotation.withName(config.annotation.name) +
      annotation.withIconColor(config.annotation.iconColor) +
      annotation.withEnable(true) +
      annotation.withHide(false) +
      annotation.datasource.withUid(config.annotation.datasource) +
      annotation.target.withType(config.annotation.type) +
      (
        if config.annotation.type == 'tags' then
          annotation.target.withMatchAny(true) +
          if std.length(config.annotation.tags) > 0 then
            annotation.target.withTags(config.annotation.tags)
          else {}
        else {}
      );

    std.prune([
      if config.annotation.enabled then customAnnotation,
    ]),

  dashboardLinks(title, config, dropdown=false, includeVars=false):: [
    dashboard.link.dashboards.new(title, config.tags) +
    dashboard.link.link.options.withTargetBlank(true) +
    dashboard.link.link.options.withAsDropdown(dropdown) +
    dashboard.link.link.options.withIncludeVars(includeVars) +
    dashboard.link.link.options.withKeepTime(true),
  ],
}
