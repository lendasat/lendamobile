use serde::{Deserialize, Serialize};

/// Historical price data point
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
pub struct HistoricalPriceData {
    pub timestamp: String,
    pub price: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HistoricalPriceResponse {
    pub prices: Vec<HistoricalPriceData>,
}

#[derive(Debug, Clone)]
pub enum TimeRange {
    OneDay,
    OneWeek,
    OneMonth,
    OneYear,
    Max,
}

impl TimeRange {
    pub fn to_query_param(&self) -> &str {
        match self {
            TimeRange::OneDay => "1D",
            TimeRange::OneWeek => "1W",
            TimeRange::OneMonth => "1M",
            TimeRange::OneYear => "1Y",
            TimeRange::Max => "MAX",
        }
    }

    pub fn from_string(s: &str) -> Option<Self> {
        match s.to_uppercase().as_str() {
            "1D" => Some(TimeRange::OneDay),
            "1W" => Some(TimeRange::OneWeek),
            "1M" => Some(TimeRange::OneMonth),
            "1Y" => Some(TimeRange::OneYear),
            "MAX" => Some(TimeRange::Max),
            _ => None,
        }
    }
}
