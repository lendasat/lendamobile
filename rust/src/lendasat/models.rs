//! Lendasat data models.
//!
//! These types match the Lendasat API OpenAPI schema and are used
//! for serialization/deserialization of API requests and responses.

use serde::{Deserialize, Serialize};

// ============================================================================
// Enums
// ============================================================================

/// Supported loan assets (stablecoins and fiat)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum LoanAsset {
    UsdcPol,
    UsdtPol,
    UsdcEth,
    UsdtEth,
    UsdcStrk,
    UsdtStrk,
    UsdcSol,
    UsdtSol,
    UsdtLiquid,
    Usd,
    Eur,
    Chf,
    Mxn,
}

impl LoanAsset {
    pub fn is_fiat(&self) -> bool {
        matches!(self, Self::Usd | Self::Eur | Self::Chf | Self::Mxn)
    }

    pub fn is_stablecoin(&self) -> bool {
        !self.is_fiat()
    }

    pub fn display_name(&self) -> &'static str {
        match self {
            Self::UsdcPol => "USDC on Polygon",
            Self::UsdtPol => "USDT on Polygon",
            Self::UsdcEth => "USDC on Ethereum",
            Self::UsdtEth => "USDT on Ethereum",
            Self::UsdcStrk => "USDC on Starknet",
            Self::UsdtStrk => "USDT on Starknet",
            Self::UsdcSol => "USDC on Solana",
            Self::UsdtSol => "USDT on Solana",
            Self::UsdtLiquid => "USDT on Liquid",
            Self::Usd => "USD",
            Self::Eur => "EUR",
            Self::Chf => "CHF",
            Self::Mxn => "MXN",
        }
    }
}

/// Collateral asset types
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum CollateralAsset {
    BitcoinBtc,
    ArkadeBtc,
}

impl CollateralAsset {
    pub fn display_name(&self) -> &'static str {
        match self {
            Self::BitcoinBtc => "Bitcoin",
            Self::ArkadeBtc => "Arkade",
        }
    }
}

/// Contract status in the loan lifecycle
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ContractStatus {
    Requested,
    Approved,
    CollateralSeen,
    CollateralConfirmed,
    PrincipalGiven,
    RepaymentProvided,
    RepaymentConfirmed,
    Undercollateralized,
    Defaulted,
    ClosingByClaim,
    Closed,
    Closing,
    ClosingByLiquidation,
    ClosedByLiquidation,
    ClosingByDefaulting,
    ClosedByDefaulting,
    Extended,
    Rejected,
    DisputeBorrowerStarted,
    DisputeLenderStarted,
    Cancelled,
    RequestExpired,
    ApprovalExpired,
    CollateralRecoverable,
    ClosingByRecovery,
    ClosedByRecovery,
}

impl ContractStatus {
    /// Check if the contract is in an active state (loan is ongoing)
    pub fn is_active(&self) -> bool {
        matches!(
            self,
            Self::CollateralConfirmed
                | Self::PrincipalGiven
                | Self::RepaymentProvided
                | Self::Undercollateralized
        )
    }

    /// Check if the contract allows claiming collateral
    pub fn can_claim(&self) -> bool {
        matches!(self, Self::RepaymentConfirmed)
    }

    /// Check if the contract allows recovery (timelock expired)
    pub fn can_recover(&self) -> bool {
        matches!(self, Self::CollateralRecoverable)
    }

    /// Check if the contract is closed/finished
    pub fn is_closed(&self) -> bool {
        matches!(
            self,
            Self::Closed
                | Self::ClosedByLiquidation
                | Self::ClosedByDefaulting
                | Self::ClosedByRecovery
                | Self::Cancelled
                | Self::RequestExpired
                | Self::ApprovalExpired
                | Self::Rejected
        )
    }

    pub fn display_name(&self) -> &'static str {
        match self {
            Self::Requested => "Requested",
            Self::Approved => "Approved",
            Self::CollateralSeen => "Collateral Seen",
            Self::CollateralConfirmed => "Collateral Confirmed",
            Self::PrincipalGiven => "Principal Given",
            Self::RepaymentProvided => "Repayment Provided",
            Self::RepaymentConfirmed => "Repayment Confirmed",
            Self::Undercollateralized => "Undercollateralized",
            Self::Defaulted => "Defaulted",
            Self::ClosingByClaim => "Closing (Claim)",
            Self::Closed => "Closed",
            Self::Closing => "Closing",
            Self::ClosingByLiquidation => "Closing (Liquidation)",
            Self::ClosedByLiquidation => "Closed (Liquidation)",
            Self::ClosingByDefaulting => "Closing (Default)",
            Self::ClosedByDefaulting => "Closed (Default)",
            Self::Extended => "Extended",
            Self::Rejected => "Rejected",
            Self::DisputeBorrowerStarted => "Dispute (Borrower)",
            Self::DisputeLenderStarted => "Dispute (Lender)",
            Self::Cancelled => "Cancelled",
            Self::RequestExpired => "Request Expired",
            Self::ApprovalExpired => "Approval Expired",
            Self::CollateralRecoverable => "Collateral Recoverable",
            Self::ClosingByRecovery => "Closing (Recovery)",
            Self::ClosedByRecovery => "Closed (Recovery)",
        }
    }
}

/// Loan offer status
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum LoanOfferStatus {
    Available,
    Unavailable,
    Deleted,
}

/// Loan payout method
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum LoanPayout {
    Direct,
    Indirect,
    MoonCardInstant,
}

/// Repayment plan type
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RepaymentPlan {
    Bullet,
    InterestOnlyWeekly,
    InterestOnlyMonthly,
}

impl RepaymentPlan {
    pub fn display_name(&self) -> &'static str {
        match self {
            Self::Bullet => "Bullet (Full at end)",
            Self::InterestOnlyWeekly => "Interest Only (Weekly)",
            Self::InterestOnlyMonthly => "Interest Only (Monthly)",
        }
    }
}

/// Installment status
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum InstallmentStatus {
    Pending,
    Paid,
    Confirmed,
    Late,
    Cancelled,
}

// ============================================================================
// Structs
// ============================================================================

/// Lender statistics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LenderStats {
    pub id: String,
    pub name: String,
    pub joined_at: String,
    pub successful_contracts: i32,
    pub vetted: bool,
    pub timezone: Option<String>,
}

/// Origination fee tier
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OriginationFee {
    pub fee: f64,
    pub from_day: i32,
}

/// Loan offer from a lender
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoanOffer {
    pub id: String,
    pub name: String,
    pub lender: LenderStats,
    pub lender_pk: String,
    pub loan_asset: LoanAsset,
    pub collateral_asset: CollateralAsset,
    pub loan_amount_min: f64,
    pub loan_amount_max: f64,
    pub duration_days_min: i32,
    pub duration_days_max: i32,
    pub interest_rate: f64,
    pub min_ltv: f64,
    pub loan_payout: LoanPayout,
    pub loan_repayment_address: String,
    pub origination_fee: Vec<OriginationFee>,
    pub repayment_plan: RepaymentPlan,
    pub status: LoanOfferStatus,
    pub kyc_link: Option<String>,
}

impl LoanOffer {
    /// Get the applicable origination fee for a given duration
    pub fn get_origination_fee(&self, duration_days: i32) -> f64 {
        self.origination_fee
            .iter()
            .filter(|f| duration_days >= f.from_day)
            .max_by_key(|f| f.from_day)
            .map(|f| f.fee)
            .unwrap_or(0.0)
    }
}

/// Loan installment (for repayment schedule)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Installment {
    pub id: String,
    pub due_date: String,
    pub principal: f64,
    pub interest: f64,
    pub status: InstallmentStatus,
    pub paid_date: Option<String>,
    pub payment_id: Option<String>,
}

impl Installment {
    pub fn total(&self) -> f64 {
        self.principal + self.interest
    }
}

/// Loan transaction record
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoanTransaction {
    pub id: i64,
    pub contract_id: String,
    pub transaction_type: String,
    pub txid: String,
    pub timestamp: String,
}

/// Loan contract
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Contract {
    pub id: String,
    pub status: ContractStatus,
    pub lender: LenderStats,
    pub lender_pk: String,
    pub borrower_pk: String,
    pub borrower_btc_address: String,
    pub borrower_derivation_path: Option<String>,
    pub borrower_loan_address: Option<String>,
    pub loan_asset: LoanAsset,
    pub collateral_asset: CollateralAsset,
    pub loan_amount: f64,
    pub interest: f64,
    pub interest_rate: f64,
    pub duration_days: i32,
    pub expiry: String,
    pub collateral_sats: i64,
    pub initial_collateral_sats: i64,
    pub deposited_sats: i64,
    pub initial_ltv: f64,
    pub liquidation_price: f64,
    pub ltv_threshold_margin_call_1: f64,
    pub ltv_threshold_margin_call_2: f64,
    pub ltv_threshold_liquidation: f64,
    pub balance_outstanding: f64,
    pub contract_address: Option<String>,
    pub collateral_script: Option<String>,
    pub loan_repayment_address: Option<String>,
    pub btc_loan_repayment_address: Option<String>,
    pub origination_fee_sats: i64,
    pub installments: Vec<Installment>,
    pub transactions: Vec<LoanTransaction>,
    pub can_extend: bool,
    pub extension_interest_rate: Option<f64>,
    pub extension_max_duration_days: i32,
    pub extends_contract: Option<String>,
    pub extended_by_contract: Option<String>,
    pub client_contract_id: Option<String>,
    pub requires_ark_settlement: Option<bool>,
    pub created_at: String,
    pub updated_at: String,
}

impl Contract {
    /// Get the next pending installment
    pub fn next_installment(&self) -> Option<&Installment> {
        self.installments
            .iter()
            .find(|i| i.status == InstallmentStatus::Pending || i.status == InstallmentStatus::Late)
    }

    /// Check if all installments are paid
    pub fn is_fully_repaid(&self) -> bool {
        self.installments
            .iter()
            .all(|i| i.status == InstallmentStatus::Confirmed || i.status == InstallmentStatus::Cancelled)
    }
}

/// Paginated contracts response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaginatedContractsResponse {
    pub data: Vec<Contract>,
    pub page: i32,
    pub limit: i32,
    pub total: i32,
    pub total_pages: i32,
}

// ============================================================================
// API Request/Response types
// ============================================================================

/// Request body for creating a contract
#[derive(Debug, Clone, Serialize)]
pub struct CreateContractRequest {
    pub id: String, // offer_id
    pub borrower_btc_address: String,
    pub borrower_pk: String,
    pub borrower_derivation_path: String,
    pub loan_amount: f64,
    pub duration_days: i32,
    pub loan_type: String, // "StableCoin"
    pub borrower_loan_address: Option<String>,
    pub borrower_npub: Option<String>,
    pub client_contract_id: Option<String>,
}

/// Serializes Option<f64> as null when None (instead of skipping the field)
fn serialize_option_f64_as_null<S>(value: &Option<f64>, serializer: S) -> Result<S::Ok, S::Error>
where
    S: serde::Serializer,
{
    match value {
        Some(v) => serializer.serialize_some(v),
        None => serializer.serialize_none(),
    }
}

/// Request body for marking installment as paid
#[derive(Debug, Clone, Serialize)]
pub struct InstallmentPaidRequest {
    pub installment_id: String,
    pub payment_id: String, // txid
    /// Optional amount paid (server requires field to be present, can be null)
    #[serde(serialize_with = "serialize_option_f64_as_null")]
    pub amount: Option<f64>,
}

/// Response from pubkey challenge request
#[derive(Debug, Clone, Deserialize)]
pub struct PubkeyChallengeResponse {
    pub challenge: String,
}

/// Request body for pubkey verification
#[derive(Debug, Clone, Serialize)]
pub struct PubkeyVerifyRequest {
    pub pubkey: String,
    pub challenge: String,
    pub signature: String,
}

/// User info from auth response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: String,
    pub name: String,
    pub email: Option<String>,
    pub verified: bool,
    pub totp_enabled: bool,
    pub created_at: String,
    pub updated_at: String,
}

/// Response from pubkey verification (login)
#[derive(Debug, Clone, Deserialize)]
pub struct PubkeyVerifyResponse {
    pub token: String,
    pub user: User,
    pub enabled_features: Vec<LoanFeature>,
}

/// Loan feature
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoanFeature {
    pub id: String,
    pub name: String,
}

/// Request body for pubkey registration
#[derive(Debug, Clone, Serialize)]
pub struct PubkeyRegisterRequest {
    pub pubkey: String,
    pub email: String,
    pub name: String,
    pub invite_code: Option<String>,
}

/// Response from pubkey registration
#[derive(Debug, Clone, Deserialize)]
pub struct PubkeyRegisterResponse {
    pub user_id: String,
}

/// Response from claim PSBT request
#[derive(Debug, Clone, Deserialize)]
pub struct ClaimPsbtResponse {
    pub psbt: String,
    pub collateral_descriptor: String,
    pub borrower_pk: String,
}

/// Response from Ark claim PSBT request
#[derive(Debug, Clone, Deserialize)]
pub struct ArkClaimPsbtResponse {
    pub ark_psbt: String,
    pub checkpoint_psbts: Vec<String>,
}

/// Response from Ark settle request
#[derive(Debug, Clone, Deserialize)]
pub struct ArkSettlePsbtResponse {
    pub intent_message: String,
    pub intent_proof: String,
    pub forfeit_psbts: Vec<String>,
    pub delegate_cosigner_pk: String,
    pub user_pk: String,
    pub derivation_path: Option<String>,
}

/// Request body for finishing Ark settlement
#[derive(Debug, Clone, Serialize)]
pub struct FinishArkSettleRequest {
    pub intent_psbt: String,
    pub forfeit_psbts: Vec<String>,
}

/// Response from finishing Ark settlement
#[derive(Debug, Clone, Deserialize)]
pub struct FinishArkSettleResponse {
    pub commitment_txid: String,
}

/// Request body for broadcasting claim/recover tx
#[derive(Debug, Clone, Serialize)]
pub struct BroadcastTxRequest {
    pub tx: String,
}

/// Request body for broadcasting Ark claim tx
#[derive(Debug, Clone, Serialize)]
pub struct BroadcastArkClaimRequest {
    pub ark_psbt: String,
    pub checkpoint_psbts: Vec<String>,
}

/// Response from broadcast (txid)
#[derive(Debug, Clone, Deserialize)]
pub struct BroadcastTxResponse {
    pub txid: String,
}

/// Response from GET /settle-ark endpoint
/// Used when contract.requires_ark_settlement is true (VTXOs are recoverable)
#[derive(Debug, Clone, Deserialize)]
pub struct SettleArkPsbtResponse {
    pub intent_message: String,
    pub intent_proof: String,
    pub forfeit_psbts: Vec<String>,
    pub delegate_cosigner_pk: String,
    pub user_pk: String,
    pub derivation_path: Option<String>,
}

/// Request body for POST /finish-settle-ark
#[derive(Debug, Clone, Serialize)]
pub struct FinishSettleArkRequest {
    pub intent_psbt: String,
    pub forfeit_psbts: Vec<String>,
}

/// Response from finish-settle-ark (commitment txid)
#[derive(Debug, Clone, Deserialize)]
pub struct FinishSettleArkResponse {
    pub commitment_txid: String,
}

/// Offer filters for API query
#[derive(Debug, Clone, Default)]
pub struct OfferFilters {
    pub loan_type: Option<String>,
    pub asset_type: Option<String>,
    pub loan_assets: Option<String>,
    pub kyc: Option<String>,
    pub min_loan_amount: Option<f64>,
    pub max_loan_amount: Option<f64>,
    pub max_interest_rate: Option<f64>,
    pub duration_min: Option<i32>,
    pub duration_max: Option<i32>,
    pub collateral_asset_type: Option<String>,
}

/// Contract filters for API query
#[derive(Debug, Clone, Default)]
pub struct ContractFilters {
    pub page: Option<i32>,
    pub limit: Option<i32>,
    pub status: Option<Vec<ContractStatus>>,
    pub sort_by: Option<String>,
    pub sort_order: Option<String>,
}
